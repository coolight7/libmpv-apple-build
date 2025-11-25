./create_libmediaxx_symb.sh
./create_libmpv_undef.sh
./create_libmpv_symb.sh

comm -12 libmediaxx_def_syms.txt libmpv_undef_syms.txt > comm_syms.txt