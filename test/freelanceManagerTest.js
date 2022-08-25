const { expect, assert } = require("chai");
const { ethers,waffle } = require("hardhat");
const provider = waffle.provider;

const {
  isCallTrace,
} = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

describe("Should test project posting", function () {
  let owner;
  let ManagerContract;
  let managerInstance;
  let projectValue = 1000

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    TokenContract = await ethers.getContractFactory("WorkToken");
    tokenInstance = await TokenContract.deploy();
    ManagerContract = await ethers.getContractFactory("WorkManager");
    managerInstance = await ManagerContract.deploy(tokenInstance.address);


    console.log("Deploying token from ",owner.address)
    console.log("Deployed token address ",tokenInstance.address)

    console.log("Owner of JOB TOKEN with all tokens ",owner.address)

    console.log("Deploying manager from ",owner.address)
    console.log("Deployed manager address ",managerInstance.address)

    console.log("Owner of JOB MANGER with all tokens ",owner.address)

  });

  it("should fail for odd number segments", async function () {
    try {
      await managerInstance.postContract("dummy URL", projectValue, 1, {
        value: web3.utils.toWei((projectValue / 2).toString(), "wei"),
      });
    } catch (error) {
      assert(
        error.message.includes(
          "Segments must be in even numbers"
        ),
        "Odd number test failed"
      );
    }
  });

  it("should fail for minimum 50% request", async function () {
    try {
      await managerInstance.postContract("dummy URL", projectValue, 2, {
        value: web3.utils.toWei(((projectValue / 2) - 1).toString(), "wei"),
      });
    } catch (error) {
      assert(
        error.message.includes(
          "Minimum 50% of contract value to be deposited."
        ),
        "Minimum deposit test failed"
      );
    }
  });

  it("should post project", async function () {
    let ownerBalance = await provider.getBalance(owner.address);
    await managerInstance.postContract("dummy URL 2", projectValue, 4, {
      value: web3.utils.toWei((projectValue / 2).toString(), "wei"),
    });
    let projectCount = await managerInstance.projectsCount();
    let projectFetched = await managerInstance.getProject(0);
    assert.equal(projectCount, 1, "Project submission test failed");
    assert.equal(owner.address, projectFetched.employer, "Owner mismatch");

  });

  it("should verify owner ", async function () {
    await managerInstance.postContract("dummy URL 1", projectValue,4, {
      value: web3.utils.toWei((projectValue / 2).toString(), "wei"),
    });
    let projectFetched = await managerInstance.getProject(0);
    assert.equal(owner.address, projectFetched.employer, "Owner mismatch");
  });

  it("should check for empty URL", async function () {
    try {
      await managerInstance.postContract("", projectValue,4, {
        value: web3.utils.toWei((projectValue / 2).toString(), "wei"),
      });
    } catch (error) {
      let projectCount = await managerInstance.projectsCount();
      assert.equal(projectCount, 0, "Empty URL check failed");
      assert(
        error.message.includes("Invalid document URLS"),
        "Submission failed with empty URL exception"
      );
    }
  });
});

describe("Should test worker undertaking", function () {
  let owner;
  let ManagerContract;
  let managerInstance;
  let worker;
  let projectFetched;
  let projectIndex = 0
  let projectValue = 1000

  beforeEach(async function () {
    [owner, worker] = await ethers.getSigners();
    TokenContract = await ethers.getContractFactory("WorkToken");
    tokenInstance = await TokenContract.deploy();
    ManagerContract = await ethers.getContractFactory("WorkManager");
    managerInstance = await ManagerContract.deploy(tokenInstance.address);


    await tokenInstance.transfer(managerInstance.address, 1000, {
      from: owner.address,
    })

    await managerInstance.postContract("dummy URL 3", projectValue,4, {
      value: web3.utils.toWei((projectValue / 2).toString(), "wei"),
    });
    
  });

  it("Emplyer should not be able to take up the project", async function () {
    try{
      await managerInstance.takeContract(projectIndex)
    }catch(error){
      assert(
        error.message.includes("Employer cannot undertake the project"),
        "Submission failed with empty URL exception"
      );
    }
   });

  it("worker should be able to take up the project", async function () {
    await managerInstance.connect(worker).takeContract(projectIndex)
    let postinstance = await managerInstance.getProject(projectIndex)        
    assert.equal(postinstance.worker, worker.address,"worker was not assigned")
   });

   it("Completion flow", async function () {
    await managerInstance.connect(worker).takeContract(projectIndex)
    let postinstance = await managerInstance.getProject(projectIndex)        
    let segments = postinstance.segments
    for(let i = 0; i < segments; i ++){
      await managerInstance.connect(worker).workerSubmission(projectIndex)
      postinstance = await managerInstance.getProject(projectIndex)        
      if(i == segments -1){
        assert.equal(postinstance.status, 4, "worker could not complete")
      }else{
        assert.equal(postinstance.status, 3, "worker could not submit the project")
      }
      if(postinstance.progress == (segments / 2) ){
        await managerInstance.employerApproval(projectIndex, {
          value: web3.utils.toWei((projectValue / 2).toString(), "wei"),
        })
      }else{
        await managerInstance.employerApproval(projectIndex)
      }
      postinstance = await managerInstance.getProject(projectIndex)
      assert.equal(postinstance.progress, i + 1, "Progress was not updated")
      if(i == segments - 1  ){
        assert.equal(postinstance.status, 4,"Employer Status was not changed to completed")
      }else{
        assert.equal(postinstance.status, 1,"Employer Status was not changed to in progress")
      }
    }
   })

})
