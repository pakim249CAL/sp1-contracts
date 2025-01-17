// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISP1Verifier, ISP1VerifierWithHash} from "../ISP1Verifier.sol";
import {PlonkVerifier} from "./PlonkVerifier.sol";

/// @title SP1 Verifier
/// @author Succinct Labs
/// @notice This contracts implements a solidity verifier for SP1.
contract SP1Verifier is PlonkVerifier, ISP1VerifierWithHash {
    /// @notice Thrown when the verifier selector from this proof does not match the one in this
    /// verifier. This indicates that this proof was sent to the wrong verifier.
    /// @param received The verifier selector from the first 4 bytes of the proof.
    /// @param expected The verifier selector from the first 4 bytes of the VERIFIER_HASH().
    error WrongVerifierSelector(bytes4 received, bytes4 expected);

    function VERSION() external pure returns (string memory) {
        return "v1.0.7-testnet";
    }

    /// @inheritdoc ISP1VerifierWithHash
    function VERIFIER_HASH() public pure returns (bytes32) {
        return 0x8c5bc5e47d8cb77f864aee881f8b66cc2457d46bd0b81b315bf82ccfadf78c50;
    }

    /// @notice Hashes the public values to a field elements inside Bn254.
    /// @param publicValues The public values.
    function hashPublicValues(bytes calldata publicValues) public pure returns (bytes32) {
        return sha256(publicValues) & bytes32(uint256((1 << 253) - 1));
    }

    /// @inheritdoc ISP1Verifier
    function verifyProof(
        bytes32 programVKey,
        bytes calldata publicValues,
        bytes calldata proofBytes
    ) external view {
        bytes4 recievedSelector = bytes4(proofBytes[:4]);
        bytes4 expectedSelector = bytes4(VERIFIER_HASH());
        if (recievedSelector != expectedSelector) {
            revert WrongVerifierSelector(recievedSelector, expectedSelector);
        }

        bytes32 publicValuesDigest = hashPublicValues(publicValues);
        uint256[] memory inputs = new uint256[](2);
        inputs[0] = uint256(programVKey);
        inputs[1] = uint256(publicValuesDigest);
        this.Verify(proofBytes[4:], inputs);
    }
}
