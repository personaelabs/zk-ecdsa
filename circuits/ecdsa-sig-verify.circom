pragma circom 2.0.2;
include "./circom-ecdsa-circuits/bigint_func.circom";
include "./circom-ecdsa-circuits/ecdsa.circom";
include "./secp256k1_scalar_mult_cached_windowed.circom";

// n: bits per register
// k: number of registers
template ECDSAVerify(n, k) {
    signal input msg[k]; // message 
    signal input r[k]; // r
    signal input pubKey[2][k]; // Pubkey
    signal input pubKeyPreComputes[32][256][2][4]; // PubKey pre computations
    signal input pubKey2[2][k]; // PubKey2

    // msg * G
    component msgMultG = ECDSAPrivToPub(n, k);
    for (var i = 0; i < k; i++) {
        msgMultG.privkey[i] <== msg[i];
    }

    component rMultPubKey = Secp256K1ScalarMultCachedWindowed(n, k);

    var stride = 8;
    var num_strides = div_ceil(n * k, stride);

    for (var i = 0; i < num_strides; i++) {
        for (var j = 0; j < 2 ** stride; j++) {
            for (var l = 0; l < k; l++) {
                rMultPubKey.pointPreComputes[i][j][0][l] <== pubKeyPreComputes[i][j][0][l];
                rMultPubKey.pointPreComputes[i][j][1][l] <== pubKeyPreComputes[i][j][1][l];
            }
        }
    }

    for (var i = 0; i < k; i++) {
        rMultPubKey.privkey[i] <== r[i];
    }

    // msg * G + r * PubKey
    component derivedPubKey2 = Secp256k1AddUnequal(n, k);
    for (var i = 0; i < k; i++) {
        derivedPubKey2.a[0][i] <== msgMultG.pubkey[0][i];
        derivedPubKey2.a[1][i] <== msgMultG.pubkey[1][i];
        derivedPubKey2.b[0][i] <== rMultPubKey.pubkey[0][i];
        derivedPubKey2.b[1][i] <== rMultPubKey.pubkey[1][i];
    }
    
    for (var i = 0; i < k; i++) {
        pubKey2[0][i] === derivedPubKey2.out[0][i];
        pubKey2[1][i] === derivedPubKey2.out[1][i];
    }
}

component main { public [pubKey2] } = ECDSAVerify(64, 4);