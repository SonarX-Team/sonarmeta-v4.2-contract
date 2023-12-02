# SonarMeta v4.2 contracts implemented with LSP

## Demo resources

- Demo website address: [https://www.sonarmeta.com](https://www.sonarmeta.com).
- Demo Next.js repo: [https://github.com/SonarX-Team/sonarmeta-v4-next](https://github.com/SonarX-Team/sonarmeta-v4-next).
- Demo video: [https://youtu.be/eT6uTgPD-d8](https://youtu.be/eT6uTgPD-d8)

## Deployed addresses on LUKSO testnet

- SonarMeta main contract: 0x8083954F57e1f13edFEa9907971208F523Ec79e6
- Creation collection contract: 0x755B6217f468DE6F8bd78Fd06eF34e7131D891B5
- Authorization collection contract: 0x5119629BB6364f377572880750DDd747d34Eac73
- Marketplace contract: 0xA2aaf36403dD4C97749Fb6CA88e7d44f1E205f3c
- ERC-6551 registry contract: 0xB6caCDa7c2Ce382D5Cc8d70F7C7f225aD3dEa642
- ERC-6551 account contract: 0x801b41437D7dbe15b8107bd5c75DA2A65Ed3fBE7

## Problem & Motivation

SonarMeta has always been interested in intellectual property (IP). Over the past decade, we have witnessed the glory of many Web2 content platforms. However, these platforms often manipulate VIEWs with algorithms for their own benefit, leading to the concentration of exposure opportunities, brand agency, and social resources on the top-tier IPs. This results in many promising IPs not fully accessing resources and prematurely fading away. Creators' earnings are often unfair, and infringement issues are becoming increasingly severe. Despite these challenges, the global IP industry is expected to have a market value of trillions of dollars.

It's crucial to recognize that with the increasingly challenging employment landscape, growing unemployment rates, and the widespread use of AIGC tools, emerging IPs continue to emerge rapidly, and predicting their upper limit in quantity is nearly impossible. While top-tier IPs hold immense value, their quantity is very limited, and the potential of tail-end IPs should far surpass that of the top-tier IPs. On the internet, we often see small IPs unexpectedly gaining popularity in a short period due to triggering recommendation algorithms. However, not every IP is so fortunate, with many facing significant resource shortages, hindering them from unlocking their potential. Therefore, it is worth considering using blockchain as a tool to decentralize VIEWs distribution. If we can unleash the potential of IPs that prematurely faded away, the overall market value will far exceed the current estimates.

Therefore, SonarMeta aims to build a decentralized network centered around IP, ensuring that the value of IP can be captured and circulated. VIEWs distribution will be determined by the entire creator ecosystem rather than being constrained by Web2 content platforms. Copyright will be fully protected, forming a network of mutually beneficial relationships among IPs. Everyone becomes a shareholder in the IPs they contribute to, enjoying the deserved benefits.

## Core Mechanism

The key to enhancing the value of an IP lies in increasing its VIEWs. One straightforward method to acquire VIEWs is by authorizing others to create derivative works. Authorization is no longer merely a grant of legitimacy to derivatives; it is also a tool for trading VIEWs. High-value IPs can sell authorizations at a premium to unleash VIEWs, while low-value IPs can sell authorizations at a lower cost or even for free to attract VIEWs. In other words, as an IP becomes more valuable, its authorizations become more expensive, and the price and circulation of authorizations can reflect the IP's value.

Therefore, we tokenize authorizations, and holders contribute and provide VIEWs to the IP by creating derivatives (or any means, such as posting on Twitter), enhancing its value. Consequently, the value of their authorization tokens increases. This incentivizes the entire creator ecosystem to assist IPs facing early resource challenges in unlocking their potential.

![whiteboard_exported_image.png](https://cdn.dorahacks.io/static/files/18c1fe2034425037b33fa2246458eff6.png)

## Key Features

- **Tokenization of Authorization**: The market value and circulation of authorization tokens, serving as tools to safeguard IP copyrights and acquire VIEWs, reflect the value of the IP.
- **Growth Loop**: When authorization exchanges result in the flow of VIEWs to an IP, it signifies an increase in the IP's value. In turn, this enhances the value of its authorization (i.e., the capacity to exchange for VIEWs), creating a growth loop for IP value.
- **Incentive Model**: As the value of authorization tokens increases with the original IP's value, holders contributing efforts are essentially investing in themselves. This aligns with an incentive-compatible stakeholder capitalism model, initiating a cycle of node growth and addressing the core issue.
- **Value Network**: When derivatives also have their derivatives, an IP value network emerges, with creations as nodes and authorizations as edges.
- **Network Effects**: As each node is supported by actual VIEWs and has a growth cycle, we can infer that the entire network's value is real and growing. It exhibits clear network effects barriers, rather than heading towards a Ponzi scheme.
- **Universal Shareholders**: With the foundation of incentive compatibility established between originals and derivatives, blockchain is used to accurately trace each creator's contribution, ensuring that all network participants receive their deserved benefits.

## Technical Architecture

SonarMeta utilizes the concept of a token-bound account (TBA) mentioned in ERC-6551 to assist NFT creations in declaring their on-chain authorization entity status. Authorization tokens are issued and received by TBAs, designating the creation issuing the authorization as Original/Issuer and the creation receiving the authorization as Derivative/Holder.

![whiteboard_exported_image.png](https://cdn.dorahacks.io/static/files/18c1fe3dbfeba84121d07164602b59a6.png)

If a creation is a co-creation, its components (such as different layers of a painting or different tracks of a song) can all be minted as NFTs and submitted to the creation's Token-Bound Account (TBA). The creator's team can deploy an IP DAO contract to manage and index the contribution level of each contributor.

![whiteboard_exported_image.png](https://cdn.dorahacks.io/static/files/18c1fe432a1e7f79a0c627f494fa502a.png)

## A possible early application scenario

Emoji packs (i.e. stickers, memes) — Spread IP in the most lightweight and efficient way! Static images, when transformed into a sticker, can express various emotions, making them more appealing to a wider audience. They can be shared effortlessly on any social media platform and spread virally in a p2p manner, without relying on centralized B2C recommendation algorithms, aligning with our expectations. Creating a set of 20-30 stickers with a reference image, can have a production cycle of less than a month. It is much simpler compared to videos and games, making it easy to attract early creators. An emoji pack can serve as an NFT collection, which we are already familiar with.

Each creation node on SonarMeta is considered a basic IP image. An original can inspire a creator to mint a derivative node and deploy a separate NFT collection to mint stickers. The sticker NFTs are treated as components, added to the derivative node's token-bound account, applying for original authorization for the entire node. Now, the emoji pack can be distributed on any social media platform, such as Discord, Telegram, WeChat, allowing enthusiasts to freely share it. Due to the similarity between the derivative and the original, they can pass VIEWs value mutually, and the creator can consistently profit through reward coins. This innovative NFT gameplay continuously can introduce NFTs into the real world and increase the user base of Web3. Creators no longer need to rely on the limited transaction volume and low prices on platforms like Opensea to make a profit.

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

## Why blockchain?

Blockchain tokenization offers the ability to concretize and capture abstract value, and provides everyone with a fair investment opportunity, allowing for transparent asset tracking and accurate distribution of returns. Investment is not limited to currency; it can be any abstract entity, such as VIEWs of a tweet, video editing skills, team collaboration, and more. Leveraging these capabilities, we can closely integrate with the current creative economy, bringing people together, ensuring unimpeded value flow, and providing each person with their deserved returns. Ultimately, it unleashes a significant amount of untapped potential.

The immense value nurtured by the IP culture industry comes from a vast community of creators. We do not wish for these values to be monopolized by centralized platforms, subject to arbitrary exploitation, as relying on any centralized platform to be objective, fair, and efficient is an uncertain prospect. Existing platforms follow hierarchical structures, making it challenging for lower-tier creators to uphold their rights. Even if they manage to do so, the speed and cost are not optimistic. However, blockchain serves not only as a means of authentication but also as a highly concurrent, objective, transparent, and efficient method. It can automatically and rapidly address the rights and profit issues of a large number of creators without overlooking small IPs.

## Wait... still have something to say in person

I've been involved in Web3 for over a year, and I’m here not because of its bull market, not for trading tokens, and I didn't even know what a token was when I first here. I got into it because I felt the call of blockchain itself to my business model. Later, I learned that everything here revolves around "whether it can be hyped." An application can surely be deployed on the blockchain, but something that can't be hyped is not used by the natives, and cryptography discourages non-natives, ultimately creating the strange logic of us having no market.

The natural barrier of cryptography is discouraging to newcomers, and fresh blood is unable to inject. Nowadays, the natives are basically endorsing the cryptocurrency market, closing off Web3 for their own entertainment, making someone like me who dislike hyping can only leave.

I want to earnestly ask: What makes us fearless when we are already on a downhill path? What makes us think that this peach blossom garden may be destroyed but doesn't matter? Is it because we think we can just run away to the next station if it cools down? Then how can we build a new generation where every user owns their assets? How dare we let data no longer be monopolized, copyrights are no longer violated, and launch the final challenge to the centralizing oligarchs who always manipulate in the dark? How dare we confidently claim that we are above Web2? If we keep discouraging newcomers, how can we rescue users who are subjected to conservative and unfair data persecution? Did we shout "All IN" only to end up with a self-glorifying sense of superiority?

Decentralization doesn't mean no center; it means everyone is a center to make it seem like there is no center. We are all nodes of Web3, everyone is the center of Web3, but now many centers are having atrial fibrillation sudden death due to a lack of fresh blood. As centers, we lack the rightful sense of ownership and have not fulfilled our obligations and responsibilities.

Seeing what Lukso has done makes me see the self-reform of Natives, and Web3 has hope. There are big players who can break free from the cryptocurrency mindset to reform. This is the most inspiring thing I have seen in over a year, rather than some token flipping 20 times. So, I am confident that the future vision of SonarMeta can definitely be realized in Web3, and the ultimate vision of Web3 can also be realized, and its value is far beyond what AI can match now (although AI has sparked a creative boom, the entire lifecycle of creation can be hosted on the blockchain). But it certainly cannot be achieved without each of us centers thinking about doing something more creative rather than native.

May we always feel honored to wear the cloak of Web3 for ourselves!
