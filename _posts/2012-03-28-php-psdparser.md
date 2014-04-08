---
layout: post
title: php-psdparser
tags: psd
---

用php写了photoshop psd文件分析脚本，它可获得文件的层信息数据，目前尚且不支持输出图片，不过晓得Image Magick的朋友可以试一试这个命令：  

<!--more-->

```sh
convert xx.psd xx.jpg
```

關於photoshop psd文件格式在這：http://wenku.baidu.com/view/f7302823482fb4daa58d4b6f.html

以下是代碼：

```php
<?PHP
class PsdParser
{
    public $fp;
    public $infoArray;

    /**
      Header mode field meanings
     */
    public static $CHANNEL_SUFFIXES = array(
            -2 => 'layer mask',
            -1 => 'A',
            0 => 'R',
            1 => 'G',
            2 => 'B',
            3 => 'RGB',
            4 => 'CMYK',
            5 => 'HSL',
            6 => 'HSB',
            9 => 'Lab',
            11 => 'RGB',
            12 => 'Lab', 
            13 => 'CMYK',
            );

    /**
      Resource id descriptions
     */
    public static $MODES = array(
            0 => 'Bitmap',
            1 => 'GrayScale',
            2 => 'IndexedColor',
            3 => 'RGBColor',
            4 => 'CMYKColor',
            5 => 'HSLColor',
            6 => 'HSBColor',
            7 => 'Multichannel',
            8 => 'Duotone',
            9 => 'LabColor',
            10 => 'Gray16',
            11 => 'RGB48',
            12 => 'Lab48',
            13 => 'CMYK64',
            14 => 'DeepMultichannel',
            15 => 'Duotone16',
            );

    public static $BLENDINGS = array(
            'norm' => 'normal',
            'dark' => 'darken',
            'mul ' => 'multiply',
            'lite' => 'lighten',
            'scrn' => 'screen',
            'over' => 'overlay',
            'sLit' => 'soft-light',
            'hLit' => 'hard-light',
            'lLit' => 'linear-light',
            'diff' => 'difference',
            'smud' => 'exclusion',
            );

    public static $COMPRESSIONS = array(
            0 => 'Raw',
            1 => 'RLE',
            2 => 'ZIP',
            3 => 'ZIPPrediction',
            );

    public function __construct($filename)
    {
        set_time_limit(0);
        $this->fp = fopen($filename, 'rb');

        $this->getHeader();
        $this->getImageResources();
        $this->getLayersAndMasks();
        $this->getImageData();
    }

    public function __get($type)
    {
        /* header, resources, layersAndMasks, image */
        $data = $this->infoArray[$type]; 
        if (isset($data)) return $data;
        else return $this->infoArray;
    }

    public function getHeader()
    {
        /* PSD Header */
        $this->infoArray['header']['sig'] = fread($this->fp, 4);
        $this->infoArray['header']['version'] = $this->_getInteger(2);
        fseek($this->fp, 6, SEEK_CUR); // 6 bytes of 0's
        $this->infoArray['header']['channels'] = $this->_getInteger(2);
        $this->infoArray['header']['rows'] = $this->_getInteger(4);
        $this->infoArray['header']['cols'] = $this->_getInteger(4);
        $this->infoArray['header']['colorDepth'] = $this->_getInteger(2);
        $this->infoArray['header']['colorMode'] = self::$MODES[$this->_getInteger(2)];

        if ($this->infoArray['header']['sig'] != '8BPS') 
            exit("Not a PSD signature.\n");
        if ($this->infoArray['header']['version'] != 1)
            exit("Can not handle PSD version.\n");
    }

    public function getImageResources()
    {
        /* COLOR MODE DATA SECTION */
        $this->infoArray['resources']['colorModeDataSectionLength'] = $this->_getInteger(4);
        fseek($this->fp, $this->infoArray['resources']['colorModeDataSectionLength'], SEEK_CUR);

        /* IMAGE RESOURCES */
        $this->infoArray['resources']['imageResourcesSectionLength'] = $this->_getInteger(4);
        fseek($this->fp, $this->infoArray['resources']['imageResourcesSectionLength'], SEEK_CUR);
    }

    public function getLayersAndMasks()
    {
        /* LAYERS AND MASKS */
        $layers = array();
        $misclen = $this->_getInteger(4);
        if ($misclen) {
            $miscstart = ftell($this->fp);  
            // process layer info section.
            $layerlen = $this->_getInteger(4);
            if ($layerlen) {
                // layers structure.
                $numLayers = $this->_getInteger(2);
                if ($numLayers < 0) {
                    $numLayers = -$numLayers;
                }
                if ($numLayers * (18 + 6 * $this->infoArray['header']['channels']) > $layerlen) {
                    echo printf("Unlikely number of %s layers for %s channels with %s layerlen. Giving up.\n", $numLayers, $this->infoArray['header']['channels'], $layerlen);
                    exit;
                }

                // collect header infos here.
                $linfo = array();
                for ($i = 0; $i < $numLayers; $i++) {
                    $l = array();
                    $l['idx'] = $i; 

                    // layer info.
                    $l['top'] = $this->_getInteger(4);
                    $l['left'] = $this->_getInteger(4);
                    $l['bottom'] = $this->_getInteger(4);
                    $l['right'] = $this->_getInteger(4);
                    $l['rows'] = $l['bottom'] - $l['top'];
                    $l['cols'] = $l['right'] - $l['left'];
                    $l['channels'] = $this->_getInteger(2);

                    // sanity check.
                    if (($l['bottom'] < $l['top'] || $l['right'] < $l['left']) || $l['channels'] > 64) {
                        fseek($this->fp, 6 * $l['channels'] + 12, SEEK_CUR);
                        // extra data.
                        $this->_skipBlock();
                        // next layer.
                        continue;
                    }

                    // read channel infos.
                    $l['chlengths'] = array();
                    $l['chids']  = array();
                    // 'hackish': addressing with -1 and -2 will wrap around to the two extra channels.
                    $l['chindex'] = array_fill(0, ($l['channels'] + 2), -1);
                    for ($j = 0; $j < $l['channels']; $j++) {
                        $chid = $this->_getInteger(2);
                        $chlen = $this->_getInteger(4);
                        $l['chids'][] = $chid;
                        $l['chlengths'][] = $chlen;
                        if ((-2 <= $chid) && ($chid < $l['channels'])) {
                            $l['chindex'][$chid] = $j;
                        } else {
                            // unexpected channel id.
                        }
                        $l['chidstr'] = isset(static::$CHANNEL_SUFFIXES[$chid]) ? static::$CHANNEL_SUFFIXES[$chid] : '?';
                    }
                    // put channel info into connection.
                    $linfo[] = $l;

                    /**
                      Blend Mode
                     */
                    $bm = array();
                    $bm['sig'] = fread($this->fp, 4);
                    $bm['key'] = fread($this->fp, 4);
                    $bm['opacity'] = $this->_getInteger(1);
                    $bm['clipping'] = $this->_getInteger(1);
                    $bm['flags'] = $this->_getInteger(1);
                    $bm['filler'] = $this->_getInteger(1);
                    $bm['opacp'] = floor(($bm['opacity'] * 100 + 127) / 255);
                    $bm['clipname'] = $bm['clipping'] ? "non-base" : "base";
                    $bm['blending'] = static::$BLENDINGS[$bm['key']];

                    $l['blend_mode'] = $bm;

                    // remember position for skipping unrecognized data.
                    $extralen = $this->_getInteger(4);
                    $extrastart = ftell($this->fp);

                    /**
                      Layer Mask Data
                     */
                    $m = array();
                    $m['size'] = $this->_getInteger(4);
                    if ($m['size']) {
                        $m['top'] = $this->_getInteger(4);
                        $m['left'] = $this->_getInteger(4);
                        $m['bottom'] = $this->_getInteger(4);
                        $m['right'] = $this->_getInteger(4);
                        $m['default_color'] = $this->_getInteger(1);
                        $m['flags'] = $this->_getInteger(1);
                        $m['rows'] = $m['bottom'] - $m['top'];
                        $m['cols'] = $m['right'] - $m['left'];
                        // skip remainder.
                        fseek($this->fp, $m['size'] - 18, SEEK_CUR);
                    }

                    $l['mask'] = $m;
                    // layer blending ranges.
                    $this->_skipBlock();

                    /**
                      Layer Name
                     */
                    $l['namelen'] = $this->_getInteger(1);
                    $l['name'] = fread($this->fp, $l['namelen']);

                    // long unicode layer name.
                    $signature = fread($this->fp, 4);
                    $key = fread($this->fp, 4);
                    $size = fread($this->fp, 4);
                    if ($key == 'luni') {
                        $i32 = fread($this->fp, 4); 
                        $namelen = ord($i32[3]) + (ord($i32[2])<<8) + (ord($i32[1])<<16) + (ord($i32[0])<<24);
                        $namelen += $namelen % 2;
                        $l['name'] = '';
                        for ($c = 0; $c < $namelen; $c ++) {
                            $i16 = fread($this->fp, 2);
                            $l['name'] += chr(ord($i16[1]) + (ord($i16[0])<<8));
                        }
                    }

                    // skip over any extra data.
                    fseek($this->fp, $extrastart + $extralen, SEEK_SET);
                    $layers[] = $l;
                }
            } else {
                exit("Layer info section is empty.\n");
            }

            $skip = $miscstart + $misclen - ftell($this->fp);
            if ($skip) {
                // skipped $skip bytes at end of misc data?
                fseek($this->fp, $skip, SEEK_CUR);
            }
        } else {
            // misc info section is empty.
        }
        $this->infoArray['layersAndMasks'] = $layers;
    }

    public function getImageData()
    {
        /* IMAGE DATA */
        $this->infoArray['image']['compressionType'] = static::$COMPRESSIONS[$this->_getInteger(2)];
    }

    private function _getInteger($byteCount = 1)
    {
        switch ($byteCount) {
            case 4:
                return @reset(unpack('N', fread($this->fp, 4)));
            case 2:
                return @reset(unpack('n', fread($this->fp, 2)));
            default :
                return @hexdec($this->_hexReverse(bin2hex(fread($this->fp, $byteCount))));
        }
    }

    private function _hexReverse($hex)
    {
        $output = '';
        if (strlen($hex)%2) return false;
        for ($pointer = strlen($hex); $pointer >= 0; $pointer -= 2)
            $output .= substr($hex, $pointer, 2);
        return $output;
    }

    private function _skipBlock()
    {
        $n = $this->_getInteger(4); // n is a 1-tuple.
        $n && fseek($this->fp, $n, SEEK_CUR); // relative.
    }
}

$parser = new PsdParser('aa.psd');
print_r($parser->header);
```
