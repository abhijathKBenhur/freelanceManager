
async function main(){
    const [deployer] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("WorkToken")
    const tokenInstance = await Token.deploy();
    console.log("tokenInstance deployed at : ",tokenInstance.address)

    const Manager = await ethers.getContractFactory("WorkManager")
    const managerInstance = await Manager.deploy(tokenInstance.address);
    console.log("managerInstance deployed at : ",managerInstance.address)
}


main().then(success => {
    process.exit(0)
}).catch(err =>{
    console.error(err) 
    process.exit(1)
})