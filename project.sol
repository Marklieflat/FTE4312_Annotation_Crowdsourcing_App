// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Need to be done:
// 1. Deposit function should be fixed to let the user specify the amount of Ether to deposit
// 2. Check the task number after the evaluation to make sure the task is deleted
// 3. Add a function to withdraw Ether from the contract
// 4. Add a function to get the balance of the contract
// 5. Restrict the taskcount to be less than 50
// 6. Add a function to get the number of tasks of a worker

// 1-2: Mark Friday
// 3-4: Glynn Saturday
// 5-6: Zekai Sunday

contract RWRC {
    // Struct for representing a task
    struct Task {
        uint id;
        string description;
        uint reward;
        address requester;
        address worker;
        bool isCompleted;
        bool isAccepted;
        string solutionHash; // Using a hash for solution
    }

    uint public taskCount;
    mapping(uint => Task) public tasks;
    mapping(address => uint) public reputation; // Worker reputation

    uint constant minimumReputation = 10; // Minimum reputation required

    // Events for logging contract actions
    event TaskCreated(uint taskId, address requester);
    event TaskAssigned(uint taskId, address worker);
    event TaskCompleted(uint taskId, address worker, string solutionHash);
    event TaskAccepted(uint taskId, bool isAccepted);
    event ReputationUpdated(address worker, uint newReputation);

    // Function to create a new task
    function createTask(string memory _description, uint _reward) public {
        taskCount++;
        tasks[taskCount] = Task(taskCount, _description, _reward, msg.sender, address(0), false, false, "");
        emit TaskCreated(taskCount, msg.sender);
    }

    // Function for workers to assign themselves a task
    function assignTask(uint _taskId) public {
        if (reputation[msg.sender] == 0) {
            // Initialize reputation to 50 for new workers
            reputation[msg.sender] = 50;
        }
        require(reputation[msg.sender] >= minimumReputation, "Insufficient reputation");
        Task storage task = tasks[_taskId];
        require(task.requester != address(0), "Task does not exist");
        require(task.worker == address(0), "Task already assigned");

        task.worker = msg.sender;
        emit TaskAssigned(_taskId, msg.sender);
    }

    // Function for workers to submit a completed task
    function completeTask(uint _taskId, string memory _solutionHash) public {
        Task storage task = tasks[_taskId];
        require(task.worker == msg.sender, "Not the assigned worker");
        require(!task.isCompleted, "Task already completed");

        task.isCompleted = true;
        task.solutionHash = _solutionHash;
        emit TaskCompleted(_taskId, msg.sender, _solutionHash);
    }

    // Function for requesters to evaluate task solutions
    function evaluateTask(uint _taskId, bool _isAccepted) public {
        Task storage task = tasks[_taskId];
        require(task.requester == msg.sender, "Not the task requester");
        require(task.isCompleted, "Task not yet completed");

        task.isAccepted = _isAccepted;
        if (_isAccepted) {
            payable(task.worker).transfer(task.reward);
            taskCount--;
            updateReputation(task.worker, true);
        } else {
            updateReputation(task.worker, false);
        }
        emit TaskAccepted(_taskId, _isAccepted);
    }

    // Internal function to update worker reputation
    function updateReputation(address _worker, bool _success) internal {
        if (_success) {
            reputation[_worker] += 5; // Increase reputation
        } else {
            if (reputation[_worker] > 5) {
                reputation[_worker] -= 5; // Decrease reputation, but not below 0
            }
        }
        emit ReputationUpdated(_worker, reputation[_worker]);
    }

    // Function to deposit Ether into the contract as rewards
    function deposit() public payable {}
}
