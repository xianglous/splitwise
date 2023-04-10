// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Splitwise {
    // DO NOT MODIFY ABOVE THIS

    // ADD YOUR CONTRACT CODE BELOW
    address[] users; // list of all unique user addresses
    mapping(address => bool) exists; // mapping from user to whether it exists
    mapping(address => int32) totalOwed; // mapping from user to total owed
    mapping(address => uint32) numCreditors; // mapping from user to number of creditors
    mapping(address => mapping(address => uint32)) debts; // mapping from user to mapping from creditor to amount

    function _addUser(address user) internal {
        if (!exists[user]) {
            exists[user] = true;
            users.push(user);
        }
    }

    function _addDebt(
        address debtor,
        address creditor,
        uint32 amount
    ) internal {
        if (debts[debtor][creditor] == 0) numCreditors[debtor]++; // new debt
        debts[debtor][creditor] += amount;
        totalOwed[debtor] += int32(amount);
        totalOwed[creditor] -= int32(amount);
    }

    function _decreaseDebt(
        address debtor,
        address creditor,
        uint32 amount
    ) internal {
        debts[debtor][creditor] -= amount;
        if (debts[debtor][creditor] == 0) numCreditors[debtor]--; // resolved debt
    }

    function getCreditors(
        address debtor
    ) public view returns (address[] memory) {
        // set memory for creditors and amounts to correct length
        address[] memory creditors = new address[](numCreditors[debtor]);
        uint32 j = 0; // index to fill
        for (uint32 i = 0; i < users.length; i++) {
            if (debts[debtor][users[i]] != 0) {
                // owe users[i]
                creditors[j] = users[i];
                j++;
            }
        }
        return creditors;
    }

    function getUsers() public view returns (address[] memory) {
        return users;
    }

    function getTotalOwed(address user) public view returns (uint32) {
        return totalOwed[user] > 0 ? uint32(totalOwed[user]) : 0; // return if total > 0 else 0
    }

    function lookup(
        address debtor,
        address creditor
    ) public view returns (uint32) {
        return debts[debtor][creditor];
    }

    function add_IOU(
        address creditor,
        uint32 amount,
        address[] calldata path
    ) public {
        address debtor = msg.sender;
        require(
            debtor != creditor,
            "Debtor cannot be the same as creditor!"
        );
        require(creditor != address(0), "Creditor cannot be empty!");
        _addDebt(debtor, creditor, amount);

        _addUser(debtor);
        _addUser(creditor);

        if (path.length > 0) {
            require(
                creditor == path[0],
                "Creditor should be at the start of the path"
            );
            require(
                debtor == path[path.length - 1],
                "Debtor should be at the end of the path"
            );
            // get minimum debt along the cycle
            uint32 min_amount = amount;
            for (uint32 i = 0; i < path.length - 1; i++) {
                uint32 amt = lookup(path[i], path[i + 1]);
                min_amount = amt < min_amount ? amt : min_amount;
            }
            // decrease all debts by min_amount
            address from = debtor;
            for (uint32 i = 0; i < path.length; i++) {
                _decreaseDebt(from, path[i], min_amount);
                from = path[i];
            }
        }
    }
}
