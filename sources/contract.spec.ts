import { toNano } from "@ton/core";
import { ContractSystem } from "@tact-lang/emulator";
import { Proxy } from "./output/sample_Proxy";
import { inspect } from "util";

describe("contract", () => {
    it("should forward messages", async () => {
        // Create ContractSystem and deploy contract
        let system = await ContractSystem.create();
        let owner = system.treasure("owner");
        let user1 = system.treasure("user1");
        let user2 = system.treasure("user2");
        let proxy = system.open(await Proxy.fromInit(owner.address));
        let proxy_tracker = system.track(proxy);
        await proxy.send(user1, { value: toNano("0.1") }, { $$type: "ProxyMessage", str: "Hello", to: user2.address });
        await system.run();
        expect(await proxy.getGetCount()).toBe(1n);
        expect((await proxy.getGetLast()).lastMessage).toEqual("Hello");
        expect((await proxy.getGetLast()).lastReciver?.equals(user2.address)).toBeTruthy();
        expect((await proxy.getGetLast()).lastSender?.equals(user1.address)).toBeTruthy();
        let proxy_events = proxy_tracker.collect();
        expect(proxy_events).toMatchSnapshot();
    });
});
