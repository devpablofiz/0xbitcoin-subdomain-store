# 0xbitcoin-subdomain-store
I'm gonna sell you 0xbitcoin.eth subdomains in exchange of 0xBTC

How to run:

create 2 files, named .secret (put your rinkeby pkey here) and .etherscan (your etherscan api key) then change truffle-config with your "from" address

yarn install

npx truffle migrate --network rinkeby

npx truffle run verify SubdomainStore --network rinkeby