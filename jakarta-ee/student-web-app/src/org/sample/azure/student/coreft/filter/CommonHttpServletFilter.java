package org.sample.azure.student.coreft.filter;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import java.io.IOException;

/**
 * Filter to extract real client IP address from HTTP headers.
 * Handles X-Forwarded-For and X-Client-IP headers for proper client identification
 * in load-balanced environments.
 */
public class CommonHttpServletFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Filter initialization logic, if needed
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        if (request instanceof HttpServletRequest) {
            HttpServletRequest httpServletRequest = (HttpServletRequest) request;

            // Extract real client IP from headers
            String realClientIP = extractRealClientIP(httpServletRequest);

            // Add the real client IP as a request attribute for downstream usage
            httpServletRequest.setAttribute("RealClientIP", realClientIP);
        }

        // Proceed with the filter chain
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // Cleanup logic, if needed
    }

    /**
     * Extracts the real client IP address from HTTP headers.
     * 
     * @param request the HTTP servlet request
     * @return the real client IP address
     */
    private String extractRealClientIP(HttpServletRequest request) {
        // Check X-Forwarded-For header first
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            // X-Forwarded-For header can contain a comma-separated list of IPs
            return xForwardedFor.split(",")[0].trim(); // Take the first IP
        }

        // Check X-Client-IP header
        String xClientIP = request.getHeader("X-Client-IP");
        if (xClientIP != null && !xClientIP.isEmpty()) {
            return xClientIP; // Use X-Client-IP directly if available
        }

        // Fallback to the remote address as last resort
        return request.getRemoteAddr();
    }
}
