# Extra root certificates

Every `.crt` in this folder is trusted inside the Linux build image, and git
ignores all of them.

You need one when something on the machine intercepts HTTPS, typically an
antivirus with web scanning (Avast, AVG, Kaspersky and ESET all do it) or a
company proxy. Windows trusts the root that signs the intercepted
connections, and the container does not. The symptom is
`server certificate verification failed` while the image clones Flutter.

To find out who signs the connection:

```bash
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null \
  | openssl x509 -noout -issuer
```

If the issuer is not a public authority, export that root from the Windows
store as PEM. Replace the subject with the one shown above:

```powershell
$c = Get-ChildItem Cert:\LocalMachine\Root |
  Where-Object Subject -like '*Avast Web/Mail Shield Root*' | Select-Object -First 1
"-----BEGIN CERTIFICATE-----`n" +
  [Convert]::ToBase64String($c.RawData, 'InsertLineBreaks').Replace("`r`n", "`n") +
  "`n-----END CERTIFICATE-----`n" |
  Set-Content -NoNewline -Encoding ascii installer\linux\extra-ca\proxy-root.crt
```

Then rebuild the image with `.\installer\build-linux.ps1 -Rebuild`.
