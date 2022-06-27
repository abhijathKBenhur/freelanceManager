
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;
import "./Utilities.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract FreelanceManager is Utilities {

enum Status {POSTED, INPROGRESS, CANCELLED, REVIEWING, PARTIAL, COMPLETED}

    struct ContractObj {
        Status status;
        address payable employer;
        address payable freelancer;
        string url;
        uint ownerShare;
        uint freelancerShare;
        uint value;
    }
    mapping(uint => ContractObj) public projects;
    uint public projectsCount = 0;

    modifier isEmployer(uint projectIndex) {
        require(msg.sender == projects[projectIndex].employer);
        _;
    }

    modifier isFreelancer(uint projectIndex) {
        require(msg.sender == projects[projectIndex].freelancer);
        _;
    }

    function getProject (uint index) public view returns(ContractObj memory) {
        return projects[index];
    }

    function postContract(string memory url,uint value) public payable returns(uint) {
        require(!_isEmpty(url),"Invalid document URLS");
        require(msg.value >= value * uint(3)/uint(4),"Minimum 75% of contract value to be deposited.");
        ContractObj memory newContract = ContractObj(
            Status.POSTED, payable(msg.sender), payable(address(0)), url, msg.value, 0 ,value 
        );
        projects[projectsCount] = newContract;
        projectsCount += 1;
        return projectsCount;
    }

    function takeContract(uint projectIndex) public payable {
        require(projects[projectIndex].employer != address(0),"Contract doesn't exist for this id.");
        require(projects[projectIndex].freelancer == address(0),"Contract already subscribed.");
        require(msg.value >= projects[projectIndex].value * uint(1)/uint(4),"Minimum 25% of contract value to be deposited.");
        projects[projectIndex].freelancer = payable(msg.sender);
        projects[projectIndex].status = Status.INPROGRESS;
        projects[projectIndex].freelancerShare = msg.value;
    }

    function freelancerSubmission(uint projectIndex) public isFreelancer(projectIndex)  {
        require(msg.sender == projects[projectIndex].freelancer,"Only freelancer can approve the completion");
        require(projects[projectIndex].status == Status.INPROGRESS,"Only an ongoing contract can be submitted");
        projects[projectIndex].status = Status.REVIEWING;
    }

    function employerApproval(uint projectIndex) public payable isEmployer(projectIndex) {
        require(msg.sender ==projects[projectIndex].employer,"Only the employer can approve");
        require(projects[projectIndex].status == Status.INPROGRESS,"Only an ongoing contract can be submitted");
        projects[projectIndex].status = Status.PARTIAL;
        //fund transfers
        projects[projectIndex].freelancer.transfer(projects[projectIndex].value * uint(3)/uint(4));

    }

    function freelancerCompletion(uint projectIndex) public isFreelancer(projectIndex) {
        require(msg.sender == projects[projectIndex].freelancer,"Only freelancer can approve the completion");
        require(projects[projectIndex].status == Status.PARTIAL,"Only an approved contract can be submitted");
        projects[projectIndex].status = Status.REVIEWING;
    }

    function employerCompletion(uint projectIndex) public payable isEmployer(projectIndex) {
        require(msg.sender == projects[projectIndex].employer,"Only employer can approve the completion");
        require(msg.value >= projects[projectIndex].value * uint(1)/uint(4),"Remaining 25% of contract value is to be deposited.");
        projects[projectIndex].status = Status.COMPLETED;
        //fund transfers
        projects[projectIndex].freelancer.transfer(uint(1)/uint(2) * projects[projectIndex].value);
    }

    function cancelContract(uint projectIndex) public payable isEmployer(projectIndex) isFreelancer(projectIndex) {
        projects[projectIndex].freelancer.transfer(projects[projectIndex].freelancerShare);
        projects[projectIndex].employer.transfer(projects[projectIndex].ownerShare);
        projects[projectIndex].status = Status.CANCELLED;

    }
}