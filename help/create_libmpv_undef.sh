readelf -W --symbols libmpv.dylib | grep ' UND ' | awk '{print $8}' | sort > libmpv_undef_syms.txt
