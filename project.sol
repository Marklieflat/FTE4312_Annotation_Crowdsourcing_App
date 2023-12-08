// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RWRC {
    struct Task {
        uint id;
        string description;
        uint reward;
        address requester;
        mapping(address => WorkerStatus) workers;
        uint workerCount;
        bool isCompleted;
        address[] workerAddresses; // Array to track worker addresses
        string[] solutionHashes; // Array of solution hashes
    }

    struct WorkerStatus {
        bool isAssigned;
        bool hasSubmitted;
    }

    uint public taskCount;
    mapping(uint => Task) public tasks;
    mapping(address => uint) public reputation;

    uint constant minimumReputation = 10;
    uint constant maxTasks = 50;

    event TaskCreated(uint taskId, address requester);
    event TaskAssigned(uint taskId, address worker);
    event TaskCompleted(uint taskId, address worker, string solutionHash);
    event TaskAccepted(uint taskId, bool isAccepted);
    event ReputationUpdated(address worker, uint newReputation);
    event DepositMade(address depositor, uint amount);

    function createTask(string memory _description, uint _reward) public {
        require(taskCount < maxTasks, "Max task limit reached");
        taskCount++;
        tasks[taskCount].id = taskCount;
        tasks[taskCount].description = _description;
        tasks[taskCount].reward = _reward;
        tasks[taskCount].requester = msg.sender;
        tasks[taskCount].workerCount = 0;
        tasks[taskCount].isCompleted = false;
        // The mapping and array will be automatically initialized to their default values

        emit TaskCreated(taskCount, msg.sender);
    }

    function assignTask(uint _taskId, address _worker) public {
        if (reputation[msg.sender] == 0) {
            // Initialize reputation to 50 for new workers
            reputation[msg.sender] = 50;
        }
        require(reputation[_worker] >= minimumReputation, "Insufficient reputation");
        Task storage task = tasks[_taskId];
        require(task.requester != address(0), "Task does not exist");
        require(!task.isCompleted, "Task already completed");

        task.workers[_worker].isAssigned = true;
        task.workerAddresses.push(_worker); // Add worker address to the array
        task.workerCount++;
        emit TaskAssigned(_taskId, _worker);
    }

    function completeTask(uint _taskId, address _worker, string memory _solutionHash) public {
        Task storage task = tasks[_taskId];
        require(task.workers[_worker].isAssigned, "Worker not assigned");
        require(!task.workers[_worker].hasSubmitted, "Solution already submitted");

        task.workers[_worker].hasSubmitted = true;
        task.solutionHashes.push(_solutionHash);
        emit TaskCompleted(_taskId, _worker, _solutionHash);

        if (task.solutionHashes.length == task.workerCount) {
            task.isCompleted = true;
            // Further logic for finalizing task completion
        }
    }

    function evaluateTask(uint _taskId, bool _isAccepted) public {
        Task storage task = tasks[_taskId];
        require(task.requester == msg.sender, "Not the task requester");
        require(task.isCompleted, "Task not yet completed");

        if (_isAccepted) {
            uint rewardPerWorker = task.reward / task.workerCount;
            for (uint i = 0; i < task.workerAddresses.length; i++) {
                address workerAddress = task.workerAddresses[i];
                payable(workerAddress).transfer(rewardPerWorker);
                updateReputation(workerAddress, true);
            }
        } else {
            for (uint i = 0; i < task.workerAddresses.length; i++) {
                updateReputation(task.workerAddresses[i], false);
            }
        }

        emit TaskAccepted(_taskId, _isAccepted);
        delete tasks[_taskId];
        taskCount--;
    }



    function updateReputation(address _worker, bool _success) internal {
        if (_success) {
            reputation[_worker] += 5;
        } else {
            if (reputation[_worker] > 5) {
                reputation[_worker] -= 5;
            }
        }
        emit ReputationUpdated(_worker, reputation[_worker]);
    }

    function deposit() public payable {
        emit DepositMade(msg.sender, msg.value);
    }

    // Get the contract's Ether balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // New function to get the number of tasks of a worker
    function getWorkerTaskCount(address _worker) public view returns (uint) {
        uint count = 0;
        for (uint i = 1; i <= taskCount; i++) {
            if (tasks[i].workers[_worker].isAssigned) {
                count++;
            }
        }
        return count;
    }

    // To check the worker is valid
    function isWorkerInAnyTask() internal view returns (bool) {
        for (uint i = 1; i <= taskCount; i++) {
            Task storage task = tasks[i];
            for (uint j = 0; j < task.workerAddresses.length; j++) {
                if (task.workerAddresses[j] == msg.sender) {
                    return true;
                }
            }
        }
        return false;
    }
    
    // Withdraw Ether from the contract
    function withdraw(uint _amount) public {
        require(isWorkerInAnyTask(), "Unauthorized: Caller is not a worker in any task");
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(msg.sender).transfer(_amount);
    }

}