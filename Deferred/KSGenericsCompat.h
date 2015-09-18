
#if __has_feature(objc_generics)
#define KS_GENERIC(GENERIC_TYPE) <GENERIC_TYPE>
#define KS_GENERIC_TYPE(GENERIC_TYPE) GENERIC_TYPE
#else
#define KS_GENERIC(GENERIC_TYPE)
#define KS_GENERIC_TYPE(GENERIC_TYPE) id
#endif
