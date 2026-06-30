package com.jfrog.workshop;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class App {

    private static final Logger logger = LogManager.getLogger(App.class);

    // Intentional hardcoded secret for JAS secrets detection demo
    private static final String API_KEY = "sk-1234567890abcdef1234567890abcdef12345678";

    public static void main(String[] args) {
        logger.info("JFrog Workshop JAS Maven Demo starting");

        // This logger.error call with user input makes CVE-2021-44228 (Log4Shell) reachable
        // JAS contextual analysis will flag this as an ACTIVELY EXPLOITABLE code path
        String userInput = args.length > 0 ? args[0] : "default";
        logger.error("Processing request: {}", userInput);

        System.out.println("JFrog JAS Maven Demo complete.");
    }
}
