
LESSC-LIVE
==========
Live less→css build tool.


NOTE: Requires [inotify](https://github.com/tong/hxinotify) which is only available on linux.


## Build/Install
```sh
## Install required libraries
haxelib install build.hxml

## Build
haxe build.hxml
```

```sh
alias lessc-live='neko /path/to/lessc-live/lessc-live.n $@'
```


## Usage
```sh
lessc-live
[-main | -m] <file>          : less index file
[-css | -c] <path>           : css file to write
[-src | -s] <path>           : paths to watch for changes (seperated by :)
[-options | -opts] <options> : lessc options (seperated by :)
```


### Example
```sh
lessc-live -main index.less -css style.css --src ./styles:path/to/a/less/lib --options --source-map:--clean-css='--s1 --advanced'
```