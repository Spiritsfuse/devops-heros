import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class App {
    public static void main(String[] args) throws IOException {
        int port = 8080;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        
        server.createContext("/", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                String response = "<!DOCTYPE html>"
                    + "<html lang=\"en\">"
                    + "<head><meta charset=\"UTF-8\"><title>Java Docker App</title>"
                    + "<style>"
                    + "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f0f4f8; }"
                    + ".card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); text-align: center; }"
                    + "h1 { color: #e76f00; margin-bottom: 10px; }"
                    + "p { color: #555; }"
                    + "</style></head>"
                    + "<body><div class=\"card\">"
                    + "<h1>Hello World from Java Web Application!</h1>"
                    + "<p>Running inside a Docker Container</p>"
                    + "</div></body></html>";
                
                byte[] bytes = response.getBytes("UTF-8");
                exchange.getResponseHeaders().set("Content-Type", "text/html; charset=UTF-8");
                exchange.sendResponseHeaders(200, bytes.length);
                OutputStream os = exchange.getResponseBody();
                os.write(bytes);
                os.close();
            }
        });

        System.out.println("Java server running on port " + port + "...");
        server.start();
    }
}
