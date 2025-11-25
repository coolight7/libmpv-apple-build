readelf -W --symbols libmediaxx.dylib | grep ' GLOBAL ' | grep -v ' UND ' | awk '{print $8}' | sort > libmediaxx_def_syms.txt
