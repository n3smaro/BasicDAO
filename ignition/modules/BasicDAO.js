const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const ONE_ETH = 1_000_000_000_000_000_000n; // 1 ETH in wei

module.exports = buildModule("BasicDAOModule", (m) => {
  const membershipFee = m.getParameter("membershipFee", ONE_ETH);  // Default to 1 ETH
  const dao = m.contract("BasicDAO", [membershipFee]);

  return { dao };
});
