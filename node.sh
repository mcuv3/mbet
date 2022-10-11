

cd ~/.chainlink-goerli && docker run -p 6688:6688 -v ~/.chainlink-goerli:/chainlink -it --env-file=.env smartcontract/chainlink:1.8.1-root local n
