diff --git i/buckets/ssl_buckets.c w/buckets/ssl_buckets.c
index b01e535..5a45868 100644
--- i/buckets/ssl_buckets.c
+++ w/buckets/ssl_buckets.c
@@ -1325,9 +1325,14 @@ static int ssl_need_client_cert(SSL *ssl, X509 **cert, EVP_PKEY **pkey)
                 return 0;
             }
             else {
+#ifdef ERR_GET_FUNC
                 printf("OpenSSL cert error: %d %d %d\n", ERR_GET_LIB(err),
                        ERR_GET_FUNC(err),
                        ERR_GET_REASON(err));
+#else
+                printf("OpenSSL cert error: %d %d\n", ERR_GET_LIB(err),
+                       ERR_GET_REASON(err));
+#endif
                 PKCS12_free(p12);
                 bio_meth_free(biom);
             }
