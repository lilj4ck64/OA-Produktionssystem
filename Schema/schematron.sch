<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    <pattern id="root">
      <rule context="/*">
          <assert test="self::book">
              Das XML-Dokument muss mit 'book' als Wurzelelement beginnen.
              gefundenes Wurzelelement: <name/>
          </assert>
      </rule>
  </pattern>
</schema>