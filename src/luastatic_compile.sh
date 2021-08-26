luajit_executable="path/to/your/luajit/bin/luajit-2.0.version"
luastatic_script="path/to/your/luastatic-master/luastatic.lua"
luajit_lib="path/to/your/luajit/lib/libluajit-5.1.a"
luajit_include="/path/to/your/luajit/include/luajit-2.0/"
cmd="${luajit_executable} ${luastatic_script} ${1} ${2} ${luajit_lib} -I${luajit_include}"
$cmd