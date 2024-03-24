import "@stdlib/ownable";
import "@stdlib/deploy";

message ProxyMessage {
    str: String;
    to: Address;
}

message ChangeExampleOwner {
    newOwner: Address;
}

struct LastMessage {
    lastMessage: String?;
    lastSender: Address?;
    lastReciver: Address?;
}

trait Stats {
    count: Int;
    lastMessage: String?;
    lastSender: Address?;
    lastReciver: Address?;

    get fun get_count(): Int {
        return self.count;
    }

    get fun get_last(): LastMessage {
        return LastMessage{
            lastMessage: self.lastMessage,
            lastSender: self.lastSender,
            lastReciver: self.lastReciver
        };
    }
}

contract Proxy with Ownable, Stats, Deployable {
    owner: Address;
    count: Int = 0;
    lastMessage: String? = null;
    lastSender: Address? = null;
    lastReciver: Address? = null;

    init(owner: Address) {
        self.owner = owner;
    }

    receive("Repeat") {
        self.requireOwner();
        send(SendParameters{
            to: self.lastReciver!!,
            value: 0,
            mode: SendRemainingValue,
            body: (self.lastMessage!!).asComment()
        });
        self.count = self.count + 1;
    }

    receive("Return") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner can call this function");
        send(SendParameters{
            to: self.lastSender!!,
            value: 0,
            mode: SendRemainingValue,
            body: (self.lastMessage!!).asComment()
        });
        self.count = self.count + 1;
    }

    receive(str: String) {
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingValue,
            body: str.asComment()
        });
        let ctx: Context = context();
        self.storeStats(ctx.sender, self.owner, str);
    }

    receive(msg: ProxyMessage) {
        send(SendParameters{
            to: msg.to, // send to the target address
            value: 0, // send 0 value
            mode: SendRemainingValue, // send remaining value
            body: msg.str.asComment() // send message
        });
        let ctx: Context = context(); // get context
        self.storeStats(ctx.sender, msg.to, msg.str); // store stats
    }   

    receive(msg: ChangeExampleOwner) {
        self.requireOwner();
        self.owner = msg.newOwner;
    }

    fun storeStats(sender: Address, receiver: Address, message: String) {
        self.count = self.count + 1;
        self.lastSender = sender;
        self.lastReciver = receiver;
        self.lastMessage = message;
    }
}