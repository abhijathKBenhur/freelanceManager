const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const {
  isCallTrace,
} = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

describe("Should test project posting", function () {
  let owner;
  let ManagerContract;
  let managerInstance;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    ManagerContract = await ethers.getContractFactory("FreelanceManager");
    managerInstance = await ManagerContract.deploy();
  });

  it("should post project", async function () {
    await managerInstance.postContract("dummy URL 2", 1000, {
      value: web3.utils.toWei("750", "wei"),
    });
    let projectCount = await managerInstance.projectsCount();
    assert.equal(projectCount, 1, "Project was not submitted");
  });

  it("should verify owner share", async function () {
    await managerInstance.postContract("dummy URL 1", 1000, {
      value: web3.utils.toWei("750", "wei"),
    });
    let projectFetched = await managerInstance.getProject(0);
    assert.equal(750, projectFetched.ownerShare, "Owner share mismatch");
  });

  it("should check minimum value project", async function () {
    try {
      await managerInstance.postContract("dummy URL", 1000, {
        value: web3.utils.toWei("749", "wei"),
      });
    } catch (error) {
      let projectCount = await managerInstance.projectsCount();
      assert.equal(projectCount, 0, "Minimum value check failed");
      assert(
        error.message.includes(
          "Minimum 75% of contract value to be deposited."
        ),
        "Submission failed with minimum value exception"
      );
    }
  });

  it("should check for empty URL", async function () {
    try {
      await managerInstance.postContract("", 1000, {
        value: web3.utils.toWei("750", "wei"),
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
