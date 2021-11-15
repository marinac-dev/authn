// ? relying_id: Relying party ID
// ? acp: Attestation conveyance preference
export const triggerAttestation = ({ challenge_b64, relying_id, user, acp }) => {
  challenge = _base64ToArrayBuffer(challenge_b64);

  const yubiChalPromise = navigator.credentials
    .create({
      publicKey: {
        challenge: challenge,
        rp: {
          id: relying_id,
          name: "WebAuthn",
        },
        user: {
          id: new Uint8Array(16),
          name: user,
          displayName: user,
        },
        pubKeyCredParams: [
          {
            type: "public-key",
            alg: -7, // "ES256" IANA COSE Algorithms registry
          },
        ],
        attestation: acp,
      },
    })
    .then((newCredential) => {
      return {
        rawID: _arrayBufferToBase64(newCredential.rawId),
        type: newCredential.type,
        clientDataJSON: _arrayBufferToString(newCredential.response.clientDataJSON),
        attestationObject: _arrayBufferToBase64(newCredential.response.attestationObject),
      };
    })
    .catch((error) => {
      console.error(error);
    });

  return yubiChalPromise;
};

export const triggerAuthentication = ({ challenge, credential_ids }) => {
  const yubiChalPromise = navigator.credentials
    .get({
      publicKey: {
        challenge: _base64ToArrayBuffer(challenge),
        allowCredentials: allowCredentialsGen(credential_ids),
      },
    })
    .then((newCredential) => {
      return {
        type: newCredential.type,
        rawID: _arrayBufferToBase64(newCredential.rawId),
        sig: _arrayBufferToBase64(newCredential.response.signature),
        clientDataJSON: _arrayBufferToString(newCredential.response.clientDataJSON),
        authenticatorData: _arrayBufferToBase64(newCredential.response.authenticatorData),
      };
    });

  return yubiChalPromise;
};

// * Helpers
const allowCredentialsGen = (credential_ids) => {
  let result = [];

  for (let i = 0; i < credential_ids.length; i++) {
    const element = credential_ids[i];
    const temp = {
      id: _base64ToArrayBuffer(element),
      type: "public-key",
      transports: ["usb", "nfc", "ble"],
    };
    result.push(temp);
  }

  return result;
};
const _arrayBufferToString = (buffer) => {
  let binary = "";
  let bytes = new Uint8Array(buffer);
  let len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return binary;
};

const _arrayBufferToBase64 = (buffer) => {
  let binary = "";
  let bytes = new Uint8Array(buffer);
  let len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return window.btoa(binary);
};

const _base64ToArrayBuffer = (base64) => {
  let binary_string = window.atob(base64);
  let len = binary_string.length;
  let bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binary_string.charCodeAt(i);
  }
  return bytes.buffer;
};
