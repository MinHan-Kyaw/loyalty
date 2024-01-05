module.export = encrypt;

function encrypt(innerText) {
  var key = "ThisIsSecretEncryptionKey";
  var base64 = CryptoJS.enc.Utf8.parse(key);
  var text = innerText;
  var encrypt = CryptoJS.TripleDES.encrypt(text, base64, {
    mode: CryptoJS.mode.ECB,
    padding: CryptoJS.pad.Pkcs7
  }
  );
  return encrypt.toString();
}