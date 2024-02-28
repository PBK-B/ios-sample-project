console.log("Hello World!", browser);

//browser.runtime.sendMessage({ greeting: "hello" }).then((response) => {
//    console.log("Received response: ", response);
//});

browser.runtime.sendNativeMessage("application.id", { message: "Hello from background page" }, function (response) {
    console.log("Received sendNativeMessage response:");
    console.log(response);
});


// 定时判断服务是否活跃
var serverView = document.getElementById("server_s")
function testServer() {
    const Http = new XMLHttpRequest();
    const url = 'http://127.0.0.1:8888';
    Http.open("GET", url);
    Http.send();

    Http.onreadystatechange = (e) => {
        var msg = "异常"
        if (Http.status == 200) {
            console.log("请求成功", Http.responseText)
            msg = "正常"
        }
        serverView.innerHTML = `服务器状态(${new Date().getTime()}): ${msg}`
    }
}
setInterval(testServer, 1000);
