<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    <pattern>  
     <rule context="/*">
          <assert test="self::book">
              Das XML-Dokument muss mit 'book' als Wurzelelement beginnen.
              gefundenes Wurzelelement: <name/>
          </assert>
      </rule>

      <rule context="contrib">
          <let name="allowed-types" value="('Autor','Gutachter')"/>
          <assert test="@contrib-type=$allowed-types">
              Jedes 'contrib'-Element muss ein 'contrib-type'-Attribut besitzen.
              Die erlaubten Werte für das 'contrib-type'-Attribut sind: <value-of select="string-join($allowed-types, ', ')"/>.
              gefundener 'contrib-type'-Attributwert: <value-of select="@contrib-type"/>
          </assert>
      </rule>
      
      <rule abstract="true" id="allowed-elements">
          <assert test="name()=$allowed-elements">
              Das Element '<name/>' ist nicht erlaubt.
              Nur die Elemente: <value-of select="string-join($allowed-elements, ', ')"/> sind erlaubt. 
          </assert>
      </rule>
      
      <rule context="name/*">
          <let name="allowed-elements" value="('degrees', 'given-names', 'surname')"/>
          <extends rule="allowed-elements"/>
      </rule>
      

      <rule context="sec/*">
          <let name="allowed-elements" value="('p', 'title', 'subtitle', 'media')"/>
          <extends rule="allowed-elements"/>
      </rule>


      <rule context="p/*">
            <let name="allowed-elements" value="('fn', 'media', 'bold', 'italic', 'sc', 'monospace', 'dip-quote')"/>
            <extends rule="allowed-elements"/>
       </rule>
        
       <rule context="media/*">
            <let name="allowed-elements" value="('uri', 'caption')"/>
            <extends rule="allowed-elements"/>
        </rule> 
  </pattern>   
</schema>