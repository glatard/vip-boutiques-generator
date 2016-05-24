/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package fr.insalyon.creatis.boutiquesvelocity;

import fr.insalyon.creatis.vip.applicationimporter.client.bean.BoutiquesTool;
import java.io.File;
import java.io.FileNotFoundException;
import java.util.Scanner;
import org.json.JSONObject;

/**
 *
 * @author Tristan Glatard
 */
public class Main {
    public static void main(String[] args) throws FileNotFoundException{
        
        // Will eventually be passed to the method.
        String jsonFileName = "/tmp/grep.json";
        
        // Will enventually be taken from the Constants.
        String wrapperTemplate   = "vm/wrapper.vm";
        String gaswTemplate            = "vm/gasw.vm";
        String gwendiaTemplate         = "vm/gwendia.vm";
        
        JSONObject jo = new JSONObject(new Scanner(new File(jsonFileName)).useDelimiter("\\Z").next());
        BoutiquesTool bt = JSONUtil.parseBoutiquesTool(jo);
        bt.setApplicationLFN("/grid/biomed/creatis/vip/applications/"+bt.getName());

        String scriptString  = VelocityUtils.getInstance().createDocument(bt, wrapperTemplate);
        String gaswString    = VelocityUtils.getInstance().createDocument(bt, gaswTemplate);
        String gwendiaString = VelocityUtils.getInstance().createDocument(bt, gwendiaTemplate);
        
        // Strings will eventually be written in a file and uploaded to the LFC.
        System.out.println(scriptString);
        System.out.println(gaswString);
        System.out.println(gwendiaString);
    }
 
}
