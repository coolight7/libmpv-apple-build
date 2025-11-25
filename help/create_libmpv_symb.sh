readelf -W --symbols libmpv.dylib | grep ' GLOBAL ' | grep -v ' UND ' | awk '{print $8}' | sort > libmpv_def_syms.txt
