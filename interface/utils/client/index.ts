import {
    createClient,
    configureChains,
    chain 
} from "wagmi";
import { infuraProvider } from 'wagmi/providers/infura';
import { INFURA_ID } from "../constants";

const { chains, provider } = configureChains(
    [chain.rinkeby],
    [infuraProvider({ apiKey: INFURA_ID })]
);

const client = createClient({
    autoConnect: true,
    provider
});

export default client;