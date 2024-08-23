//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "forge-std/Vm.sol";

contract ScaffoldETHDeploy is Script {
  error InvalidChain();
  
  event AnvilSetBalance(address account, uint256 amount);
  event FailedAnvilRequest();

  struct Deployment {
    string name;
    address addr;
  }

  string root;
  string path;
  Deployment[] public deployments;

  function deployContractWithSafeSign(bytes memory code) internal {
    console2.log(vm.toString(code));
    this.anvil_setBalance(address(0x92f444Fc0CDa9D47521fB1D53672c4c2898e2328), 100 ether);
    // string[] memory start = new string[](2);
    // inputs[0] = "yarn";
    // inputs[1] = "safeSign:start";

    // string[] memory start = new string[](2);
    // inputs[0] = "curl";
    // inputs[1] = "";
   
    // bytes memory res = vm.ffi(start);
    // // string memory output = abi.decode(res, (string));
    // console2.log(string(res));

    // bytes memory res2 = vm.ffi()
  }

  function setupLocalhostEnv() internal returns (uint256 localhostPrivateKey) {
    if (block.chainid == 31337) {
      root = vm.projectRoot();
      path = string.concat(root, "/localhost.json");
      string memory json = vm.readFile(path);
      bytes memory mnemonicBytes = vm.parseJson(json, ".wallet.mnemonic");
      string memory mnemonic = abi.decode(mnemonicBytes, (string));
      return vm.deriveKey(mnemonic, 0);
    } else {
      return vm.envUint("DEPLOYER_PRIVATE_KEY");
    }
  }

  function exportDeployments() internal {
    // fetch already existing contracts
    root = vm.projectRoot();
    path = string.concat(root, "/deployments/");
    string memory chainIdStr = vm.toString(block.chainid);
    path = string.concat(path, string.concat(chainIdStr, ".json"));

    string memory jsonWrite;

    uint256 len = deployments.length;

    for (uint256 i = 0; i < len; i++) {
      vm.serializeString(
        jsonWrite, vm.toString(deployments[i].addr), deployments[i].name
      );
    }

    string memory chainName;

    try this.getChain() returns (Chain memory chain) {
      chainName = chain.name;
    } catch {
      chainName = findChainName();
    }
    jsonWrite = vm.serializeString(jsonWrite, "networkName", chainName);
    vm.writeJson(jsonWrite, path);
  }

  function getChain() public returns (Chain memory) {
    return getChain(block.chainid);
  }

  function findChainName() public returns (string memory) {
    uint256 thisChainId = block.chainid;
    string[2][] memory allRpcUrls = vm.rpcUrls();
    for (uint256 i = 0; i < allRpcUrls.length; i++) {
      try vm.createSelectFork(allRpcUrls[i][1]) {
        if (block.chainid == thisChainId) {
          return allRpcUrls[i][0];
        }
      } catch {
        continue;
      }
    }
    revert InvalidChain();
  }

  function anvil_setBalance(address addr, uint256 amount) public {
    string memory addressString = vm.toString(addr);
    string memory amountString = vm.toString(amount);
    string memory requestPayload = string.concat(
      '{"method":"anvil_setBalance","params":["',
      addressString,
      '","',
      amountString,
      '"],"id":1,"jsonrpc":"2.0"}'
    );

    string[] memory inputs = new string[](8);
    inputs[0] = "curl";
    inputs[1] = "-X";
    inputs[2] = "POST";
    inputs[3] = "http://localhost:8545";
    inputs[4] = "-H";
    inputs[5] = "Content-Type: application/json";
    inputs[6] = "--data";
    inputs[7] = requestPayload;

    vm.ffi(inputs);
  }
}
