
LESSC-LIVE
==========
Live lessc.


## Usage
```
lessc-live --help
[-main | -m] <file>   : less index file
[-css | -out] <path>  : css file to write
[-src] <path>         : paths to watch for changes
[--options] <options> : lessc options
```

### Example
```
hl lessc-live.hl -main styles/index.less -css style.css -src styles:/home/tong/dev/lib/enron/src/enron -options --source-map:--clean-css='--s1 --advanced'
```