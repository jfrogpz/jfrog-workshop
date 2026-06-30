package com.jfrog.workshop;

import org.apache.commons.lang3.StringUtils;

public class App {
    public static void main(String[] args) {
        String msg = StringUtils.capitalize("jfrog workshop — artifactory-maven sample");
        System.out.println(msg);
    }
}
