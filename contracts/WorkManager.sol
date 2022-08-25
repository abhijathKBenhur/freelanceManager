
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;
import "./Utilities.sol";
import "./WorkToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract WorkManager is Utilities {

enum Status {POSTED, INPROGRESS, CANCELLED, REVIEWING, COMPLETED}
    WorkToken token;

    constructor(address workTokenAddress){
        token = WorkToken(workTokenAddress);
    }

    struct ContractObj {
        Status status;
        address payable employer;
        address payable worker;
        string url;
        uint ownerShare;
        uint value;
        uint segments;
        uint progress;
    }


    event stateChanged(
        uint projectId,
        uint progress,
        uint32 status
    );


    mapping(uint => ContractObj) public projects;
    uint public projectsCount = 0;

    modifier isEmployer(uint projectIndex) {
        require(msg.sender == projects[projectIndex].employer);
        _;
    }

    modifier isWorker(uint projectIndex) {
        require(msg.sender == projects[projectIndex].worker);
        _;
    }

    function getProject (uint index) public view returns(ContractObj memory) {
        return projects[index];
    }

    function postContract(string memory _url,uint _value,uint _segments) public payable returns(uint) {
        require(!_isEmpty(_url),"Invalid document URLS");
        require(_segments % 2 == 0,"Segments must be in even numbers");
        require(msg.value == _value * uint(1)/uint(2),"Minimum 50% of contract value to be deposited.");
        ContractObj memory newContract = ContractObj(
            Status.POSTED, payable(msg.sender), payable(address(0)), _url, msg.value ,_value , _segments, 0
        );
        projects[projectsCount] = newContract;
        emit stateChanged(projectsCount,0, uint32(Status.POSTED));
        projectsCount += 1;
        return projectsCount;
    }

    function takeContract(uint projectIndex) public {
        require(projects[projectIndex].employer != address(0),"Contract doesn't exist for this id.");
        require(projects[projectIndex].worker == address(0),"Contract already subscribed.");
        require(msg.sender != projects[projectIndex].employer,"Employer cannot undertake the project.");
        projects[projectIndex].worker = payable(msg.sender);
        projects[projectIndex].status = Status.INPROGRESS;
        emit stateChanged(projectIndex,0, uint32(Status.INPROGRESS));
    }

    function employerApproval(uint projectIndex) public payable isEmployer(projectIndex) {
        require(msg.sender ==projects[projectIndex].employer,"Only the employer can approve");
        require(projects[projectIndex].status == Status.REVIEWING || projects[projectIndex].status == Status.COMPLETED,"Only an ongoing contract can be submitted");
        if(projects[projectIndex].progress == (projects[projectIndex].segments / 2) ){
            require(msg.value == projects[projectIndex].value * uint(1)/uint(2),"Remaining 50% of contract value to be deposited.");
            projects[projectIndex].ownerShare += msg.value;
        }
        projects[projectIndex].worker.transfer(projects[projectIndex].value / projects[projectIndex].segments);
        projects[projectIndex].progress += 1;

        if(projects[projectIndex].progress != projects[projectIndex].segments){
            projects[projectIndex].status = Status.INPROGRESS;
        }else{
            console.log("WT balance of sender", msg.sender);
            console.log(token.balanceOf( msg.sender));
            console.log("this",address(this));
            console.log(token.balanceOf( address(this)));

            token.transfer(projects[projectIndex].worker, 100);
            token.transfer(projects[projectIndex].employer, 100);
            console.log("WT balance", projects[projectIndex].employer);
            console.log(token.balanceOf(projects[projectIndex].employer));

            console.log("WT balance", projects[projectIndex].worker);
            console.log(token.balanceOf(projects[projectIndex].worker));
            
        }
        emit stateChanged(projectIndex,projects[projectIndex].progress, uint32(Status.INPROGRESS));
        unchecked {
            uint partTransferred = projects[projectIndex].value / projects[projectIndex].segments;
            uint currentBalance = projects[projectIndex].ownerShare - partTransferred;
            require(currentBalance <= partTransferred, "Your custom message here");
            projects[projectIndex].ownerShare = currentBalance;
        }
    }

    function workerSubmission(uint projectIndex) public isWorker(projectIndex) {
        require(msg.sender == projects[projectIndex].worker,"Only worker can approve the completion");
        if(projects[projectIndex].progress == projects[projectIndex].segments - 1){
            projects[projectIndex].status = Status.COMPLETED;
        }else{
            projects[projectIndex].status = Status.REVIEWING;
        }
        emit stateChanged(projectIndex,projects[projectIndex].progress, uint32(projects[projectIndex].status));
    }

    function cancelContract(uint projectIndex) public payable isEmployer(projectIndex) isWorker(projectIndex) {
        require(projects[projectIndex].status != Status.COMPLETED,"Completed contracts cannot be cancelled");
        projects[projectIndex].worker.transfer( projects[projectIndex].ownerShare / 10);
        projects[projectIndex].employer.transfer(projects[projectIndex].ownerShare / 90);
        projects[projectIndex].status = Status.CANCELLED;
        emit stateChanged(projectIndex,projects[projectIndex].progress, uint32(Status.CANCELLED));

    }
}