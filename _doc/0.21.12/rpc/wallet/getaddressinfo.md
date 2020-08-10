---
name: getaddressinfo
version: 0.21.12
group: wallet
permalink: doc/0.21.12/rpc/wallet/getaddressinfo/
---

getaddressinfo "address"

Return information about the given bitcoin address. Some information requires the address
to be in the wallet.

Arguments:
1. address    (string, required) The bitcoin address to get the information of.

Result:
{
  "address" : "address",      (string) The bitcoin address validated
  "scriptPubKey" : "hex",     (string) The hex-encoded scriptPubKey generated by the address
  "ismine" : true|false,        (boolean) If the address is yours or not
  "iswatchonly" : true|false,   (boolean) If the address is watchonly
  "solvable" : true|false,      (boolean) Whether we know how to spend coins sent to this address, ignoring the possible lack of private keys
  "desc" : "desc",            (string, optional) A descriptor for spending coins sent to this address (only when solvable)
  "isscript" : true|false,      (boolean) If the key is a script
  "ischange" : true|false,      (boolean) If the address was used for change output
  "script" : "type"           (string, optional) The output script type. Only if "isscript" is true and the redeemscript is known. Possible types: nonstandard, pubkey, pubkeyhash, scripthash, multisig, nulldata
  "hex" : "hex",              (string, optional) The redeemscript for the p2sh address
  "pubkeys"                     (string, optional) Array of pubkeys associated with the known redeemscript (only if "script" is "multisig")
    [
      "pubkey"
      ,...
    ]
  "sigsrequired" : xxxxx        (numeric, optional) Number of signatures required to spend multisig output (only if "script" is "multisig")
  "pubkey" : "publickeyhex",  (string, optional) The hex value of the raw public key, for single-key addresses (possibly embedded in P2SH)
  "embedded" : {...},           (object, optional) Information about the address embedded in P2SH, if relevant and known. It includes all getaddressinfo output fields for the embedded address, excluding metadata ("timestamp", "hdkeypath", "hdseedid") and relation to the wallet ("ismine", "iswatchonly").
  "iscompressed" : true|false,  (boolean) If the address is compressed
  "label" :  "label"          (string) The label associated with the address, "" is the default label
  "timestamp" : timestamp,      (number, optional) The creation time of the key if available in seconds since epoch (Jan 1 1970 GMT)
  "hdkeypath" : "keypath"     (string, optional) The HD keypath if the key is HD and available
  "hdseedid" : "<hash160>"    (string, optional) The Hash160 of the HD seed
  "hdmasterfingerprint" : "<hash160>" (string, optional) The fingperint of the master key.
  "labels"                      (object) Array of labels associated with the address.
    [
      { (json object of label data)
        "name": "labelname" (string) The label
        "purpose": "string" (string) Purpose of address ("send" for sending address, "receive" for receiving address)
      },...
    ]
}

Examples:
> bitcoin-cli getaddressinfo "1PSSGeFHDnKNxiEyFrD1wcEaHr9hrQDDWc"
> curl --user myusername --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getaddressinfo", "params": ["1PSSGeFHDnKNxiEyFrD1wcEaHr9hrQDDWc"] }' -H 'content-type: text/plain;' http://127.0.0.1:8332/

