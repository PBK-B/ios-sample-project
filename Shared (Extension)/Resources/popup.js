console.log("Hello World!", browser);

//browser.runtime.sendMessage({ greeting: "hello" }).then((response) => {
//    console.log("Received response: ", response);
//});

browser.runtime.sendNativeMessage("application.id", {message: "Hello from background page"}, function(response) {
    console.log("Received sendNativeMessage response:");
    console.log(response);
});
