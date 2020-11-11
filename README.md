
LESSC-LIVE
==========
Live less→css build tool.


NOTE: Requires [inotify](https://github.com/tong/hxinotify) which is only available on linux.


## Usage
```sh
neko lessc-live.n
[-main | -m] <file>          : less index file
[-css | -c] <path>           : css file to write
[-src | -s] <path>           : paths to watch for changes (seperated by :)
[-options | -opts] <options> : lessc options (seperated by :)
```

### Example
```sh
neko lessc-live.n -main index.less -css style.css -src ./styles:path/to/a/less/lib -options --source-map:--clean-css='--s1 --advanced'
```