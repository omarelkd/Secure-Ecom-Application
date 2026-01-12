package ma.enset.gateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class AuthenticationHeaderFilter implements GlobalFilter, Ordered {

    private static final Logger log = LoggerFactory.getLogger(AuthenticationHeaderFilter.class);

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getPath().toString();
        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        
        log.info("Gateway Filter - Path: {}, Authorization header present: {}", 
                path, authHeader != null);
        
        if (authHeader != null) {
            log.info("Authorization header value: {}", authHeader.substring(0, Math.min(20, authHeader.length())) + "...");
        }
        
        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
