# SonarMeta v4.2 contracts implemented with LSP

## Demo resources

- Demo website address: [https://www.sonarmeta.com](https://www.sonarmeta.com).
- Demo Next.js repo: [https://github.com/SonarX-Team/sonarmeta-v4-next](https://github.com/SonarX-Team/sonarmeta-v4-next).
- Demo video: [https://youtu.be/eT6uTgPD-d8](https://youtu.be/eT6uTgPD-d8)

## SonarMeta Overview

### Motivation

SonarMeta has always been interested in IP. Over the past decade, we have witnessed the glory of many Web2 content platforms. However, for their own interests, platform operators manipulate traffic precisely through algorithms, resulting in the concentration of most exposure opportunities, brand agencies, and social resources on the top popular IPs. Even if it's unfair, the estimated global market value of the IP industry is in trillions of dollars. This leads us to firmly believe that unlocking the potential of IPs that have prematurely faltered due to traffic issues will undoubtedly unleash a powerful force, much like detonating a nuclear weapon.

### Core mechanism

Let's say, if increasing traffic can enhance the value of an IP, then a straightforward way to acquire traffic is by authorizing others to create derivatives. Authorization, is not only about granting legitimacy but also serves as a tool for trading traffic. High-value IPs can sell authorizations at a premium to unleash traffic, while low-value IPs may sell them at lower or even for free to attract traffic. Therefore, we tokenize authorizations, and as they circulate, the derivatives created by holders contribute traffic to enhance the value of the IP. When an IP becomes more valuable, the token's price for authorizations will increase. This incentivizes the entire creator ecosystem to assist IPs facing early resource challenges in unlocking their potential.

### Getting started

If you are a new user of SonarMeta, the first step is to create a node. This involves a creation NFT and a token-bound account that exercises on-chain sovereignty for it. Deploying this TBA allows users to send transactions on behalf of it, and this is a global operation. Signing is equivalent to registering the TBA on SonarMeta, making it easier for us to track holder data and node value. Activating means the node can act as an issuer for authorizations. Each step requires gas, so users can choose to what extent they want to engage.

Suppose another user sees and really likes your creation one day, and decides to create a derivative for you. That guy can deploy and sign this node, then apply for authorization on your creation page. At this point, you can visit the studio to review and authorize the application, making the derivative a holder of your creation. Then it can receive your airdrop, and when the value of your node increases, it can sell the tokens at a better price, creating a mutually beneficial situation. Now, anyone who likes, wants to contribute, seeks exposure, or has confidence in your creation can buy your tokens and contribute to making higher prices.

### Further more with co-creation

TBA can also serve as a repository for co-creation. If a creation involves a team rather than a solo effort, such as a painting by a group, different layers can be minted as component NFTs and submitted to the TBA of the co-creation. The contribution of each member can be tracked by a separate contract.

### Give birth to the value network

In the end, when derivatives also activate authorization functionalities, and derivatives of derivatives start to emerge, a value network is formed. Nodes that join earlier will receive more profits sooner, and there are more interesting tokenomic features waiting to be explored on this network.

### More information about SonarMeta

Please check the doc [Introducing SonarMeta](https://sonarx666.feishu.cn/docx/XyLndXhftoXz1GxkCYAcOIdrn1U?from=from_copylink).

## To the Judges of LUKSO BuildUP #2

First and foremost, We would like to extend our sincere respect to the founders and developers of LUKSO. You guys are doing truly amazing work. If you've read something about SonarMeta above, you'll easily discover that our project is specifically designed as an incentive and empowerment tool for IP creator communities. We aim to transform them from social into stakeholder relationships, unleashing unprecedented value. However, this has not always been a focal point favored by the Web3 native. Natives have traditionally been more focused on somethingFi and whether tokens can appreciate, which has been a constant challenge for us.

But today, Lukso has indeed solved our concerns. Although the idea we came up with lives for only three months, we want you to know a feedback from us that your efforts have truly addressed the challenges faced by dApp developers focusing on creative communities. Well done!

## Frontend simulations

Unfortunately, for the entire first 20 days of November, we were working on implementing our demo using ERC and MetaMask and deploying it on Polygon Mumbai. Before that, we had not heard about Lukso. So, when we saw buildup#2 a few days ago and spent a few more days learning about LSP and UP, it was too late for us to adapt the entire contract and website code to LSP and the browser extensions. However, in these past two days, we managed to complete the implementation of the LSP contract and the simulated typescript code. We still hope to participate in this hackathon to have a chance to let you see our demo and video.

Since we believe that technical adaptation is ultimately a matter of time. A creative idea and use case, along with a convincing business model, should still be the focal points that you favor more in this hackathon.

- Create a Network node (mint a creation NFT) - ./scripts/create-node.ts
- Deploy, sign, and activate the corresponding Token-bound account - ./scripts/tokenbound-accounts.ts
- Authorize to create a network edge (mint a authorization collection token) - ./scripts/authorize.ts
- Give bonus to a holder node (mint authorization NFT tokens) - ./scripts/give-bonus.ts
- List authorization tokens to the marketplace - ./scripts/list-to-marketplace.ts
- Buy authorization tokens on the marketplace - ./scripts/buy-from-marketplace.ts

## Wait... still have something to say in person

I've been involved in Web3 for over a year, and I’m here not because of its bull market, not for trading tokens, and I didn't even know what a token was when I first here. I got into it because I felt the call of blockchain itself to my business model. Later, I learned that everything here revolves around "whether it can be hyped." An application can surely be deployed on the blockchain, but something that can't be hyped is not used by the natives, and cryptography discourages non-natives, ultimately creating the strange logic of us having no market.

The natural barrier of cryptography is discouraging to newcomers, and fresh blood is unable to inject. Nowadays, the natives are basically endorsing the cryptocurrency market, closing off Web3 for their own entertainment, making someone like me who dislike hyping can only leave.

I want to earnestly ask: What makes us fearless when we are already on a downhill path? What makes us think that this peach blossom garden may be destroyed but doesn't matter? Is it because we think we can just run away to the next station if it cools down? Then how can we build a new generation where every user owns their assets? How dare we let data no longer be monopolized, copyrights are no longer violated, and launch the final challenge to the centralizing oligarchs who always manipulate in the dark? How dare we confidently claim that we are above Web2? If we keep discouraging newcomers, how can we rescue users who are subjected to conservative and unfair data persecution? Did we shout "All IN" only to end up with a self-glorifying sense of superiority?

Decentralization doesn't mean no center; it means everyone is a center to make it seem like there is no center. We are all nodes of Web3, everyone is the center of Web3, but now many centers are having atrial fibrillation sudden death due to a lack of fresh blood. As centers, we lack the rightful sense of ownership and have not fulfilled our obligations and responsibilities.

Seeing what Lukso has done makes me see the self-reform of Natives, and Web3 has hope. There are big players who can break free from the cryptocurrency mindset to reform. This is the most inspiring thing I have seen in over a year, rather than some token flipping 20 times. So, I am confident that the future vision of SonarMeta can definitely be realized in Web3, and the ultimate vision of Web3 can also be realized, and its value is far beyond what AI can match now (although AI has sparked a creative boom, the entire lifecycle of creation can be hosted on the blockchain). But it certainly cannot be achieved without each of us centers thinking about doing something more creative rather than native.

May we always feel honored to wear the cloak of Web3 for ourselves！
