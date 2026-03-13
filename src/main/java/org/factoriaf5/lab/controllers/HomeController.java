package org.factoriaf5.lab.controllers;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;

@RestController
@RequestMapping("/api")
public class HomeController {

    @GetMapping("")
    public String index() {
        return new String("Giacomo 15 - nosotros 1");
    }

}
