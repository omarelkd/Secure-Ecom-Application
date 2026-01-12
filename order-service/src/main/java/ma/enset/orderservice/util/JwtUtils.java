package ma.enset.orderservice.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.Base64;
import java.util.Map;

@Component
public class JwtUtils {

    private final ObjectMapper objectMapper = new ObjectMapper();

    public String extractUsernameFromToken(String token) {
        if (token == null || !token.startsWith("Bearer ")) {
            return "anonymous";
        }

        try {
            // Remove "Bearer " prefix
            String jwt = token.substring(7);
            
            // JWT format: header.payload.signature
            String[] parts = jwt.split("\\.");
            if (parts.length < 2) {
                return "anonymous";
            }

            // Decode payload (second part)
            String payload = new String(Base64.getUrlDecoder().decode(parts[1]));
            
            // Parse JSON to extract preferred_username
            @SuppressWarnings("unchecked")
            Map<String, Object> claims = objectMapper.readValue(payload, Map.class);
            
            String username = (String) claims.get("preferred_username");
            return username != null ? username : "anonymous";
            
        } catch (Exception e) {
            return "anonymous";
        }
    }
}
