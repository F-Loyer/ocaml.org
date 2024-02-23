---
packages:
- name: "x509"
  version: "0.16.5"
- name: "mirage-crypto-rng"
  version: "0.11.2"
sections:
- filename: main.ml
  language: ocaml
  code_blocks:
  - explanation: |
      The signature function needs a initialized random number generator.
    code: |
      Mirage_crypto_rng_unix.initialize (module Mirage_crypto_rng.Fortuna);;
  - explanation: |
      Use the `x509` library and sign a given message.
    code:
	  let message = "hello"
      let signature = match X509.Private_key.sign `SHA384 private_key
        (`Message (Cstruct.of_string message)) with
           | Ok sign -> sign
           | Error (`Msg error) -> failwith error;;
  - explanation: |
      Use the `x509` library and verify the signature with a public_key.
    code:
      let () = match X509.Public_key.verify `SHA384 ~signature public_key 
	     (`Message (Cstruct.of_string message)) with
		   | Ok () -> print_string "verication successfull"
		   | Error (`Msg error) -> failwith error;;

---

- **Understanding `X509`:** The `X509.sign` and `X509.verify` functions respectively signs a message (with the private key) and verifies the returned signature (with the public key). The private and public keys are given by the `X509` module (see the [cookbook about opening certificates and private keys](/cookbook/cryptography/opening_certificates_and_keys). Note: a full verification of a signature needs to check the certificate from which the public key is obtain (is its root CA trusted? is the certificate valid?).
- **Allowed algorithm**: The `X509.Private_key.sign` and `verify` functions have an optional `?scheme` parameter. The default value is used in the snipset, but it should be set according to the X509 certificate. (See `X509.Certificate.signature_algorithm`). The hash algorithm (here `\`SHA384`) should be set to this function result too.
- **Alternative**: The `Mirage_crypto_pk` module provides lower level signature/verification functions.
