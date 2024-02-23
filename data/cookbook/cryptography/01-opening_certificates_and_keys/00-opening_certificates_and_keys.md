---
packages:
- name: "x509"
  version: "0.16.5"
sections:
- filename: main.ml
  language: ocaml
  code_blocks:
  - explanation: |
      A simple function which read a file and convert to a `Cstruct` type.
    code: |
      let read_file file_name =
      Cstruct.of_string (In_channel.with_open_text file_name In_channel.input_all);;
  - explanation: |
      Use the `x509` library and read a public key from a certificate.
    code:
      let public_key =
        match read_file "certificate.pem" |> X509.Certificate.decode_pem with
        | Ok cert ->
            X509.Certificate.public_key cert
        | Error (`Msg msg) -> failwith msg;;
  - explanation: |
      Use the `x509` library and read a private key from a PKCS12 file.
    code:
      let private_key = 
	    match read_file "key.pem" |> X509.Private_key.decode_pem with
        | Ok key -> 
        | Error (`Msg msg) -> failwith msg;;

---

- **Understanding `X509`:** The `X509.Certificate.decode_pem` function decode a certificate given in a `cstruct` type. If the decoding succeed, it will match `Ok cert`, and we can use the result with the `X509.Certificate.public_key` which returns the expected public key. The type for public keys is defined by the [`X509.Public_key` module](https://mirleft.github.io/ocaml-x509/doc/x509/X509/Public_key/index.html). The `X509.Private_key.decode_pem` decodes a PKCS12 private key in a `cstruct` type. If the decoding succeed, it will match `Ok k` where `k` is the private key. The type for private keys is defined by the [`X509.Private_key` module](https://mirleft.github.io/ocaml-x509/doc/x509/X509/Private_key/index.html)
