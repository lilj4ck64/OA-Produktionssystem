package oa.tools;

import com.adobe.epubcheck.api.EPUBLocation;
import com.adobe.epubcheck.api.EpubCheck;
import com.adobe.epubcheck.api.MasterReport;
import com.adobe.epubcheck.messages.Message;
import com.adobe.epubcheck.messages.Severity;
import com.adobe.epubcheck.util.FeatureEnum;
import com.sun.msv.verifier.ErrorInfo;
import com.sun.msv.verifier.ValidityViolation;
import com.sun.msv.verifier.jarv.DTDFactoryImpl;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XsltCompiler;
import net.sf.saxon.s9api.XsltExecutable;
import net.sf.saxon.s9api.XsltTransformer;
import org.apache.fop.apps.FOUserAgent;
import org.apache.fop.apps.Fop;
import org.apache.fop.apps.FopConfParser;
import org.apache.fop.apps.FopFactory;
import org.apache.fop.apps.MimeConstants;
import org.apache.fop.events.Event;
import org.apache.fop.events.EventFormatter;
import org.apache.fop.events.model.EventSeverity;
import org.iso_relax.verifier.Schema;
import org.iso_relax.verifier.Verifier;
import org.xml.sax.ErrorHandler;
import org.xml.sax.Locator;
import org.xml.sax.SAXParseException;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.SourceLocator;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.stream.StreamSource;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Calls the bundled tools through their public APIs and emits structured
 * diagnostics. DTD validation can report multiple independent violations;
 * the other tools return their first relevant failure. Human-oriented console
 * output is intentionally not part of the protocol consumed by Go.
 */
public final class ToolAdapter {
    private ToolAdapter() {
    }

    public static void main(String[] args) {
        String tool = args.length == 0 ? "Werkzeug" : args[0];
        try {
            if ("dtd".equals(tool)) {
                requireArgs(args, 3);
                List<Diagnostic> diagnostics = validateDTD(new File(args[1]), new File(args[2]));
                if (!diagnostics.isEmpty()) {
                    emit(diagnostics);
                    System.exit(2);
                }
                return;
            }
            Diagnostic diagnostic;
            switch (tool) {
                case "fop":
                    requireArgs(args, 8);
                    diagnostic = buildPDF(args);
                    break;
                case "saxon":
                    requireArgs(args, 7);
                    diagnostic = transformEPUB(args);
                    break;
                case "epubcheck":
                    requireArgs(args, 2);
                    diagnostic = validateEPUB(new File(args[1]));
                    break;
                default:
                    throw new IllegalArgumentException("Unbekanntes Werkzeug: " + tool);
            }
            if (diagnostic != null) {
                emit(diagnostic);
                System.exit(2);
            }
        } catch (Throwable failure) {
            emit(Diagnostic.fromThrowable(failure));
            System.exit(2);
        }
    }

    private static List<Diagnostic> validateDTD(File dtd, File xml) throws Exception {
        DTDFactoryImpl factory = new DTDFactoryImpl();
        Schema schema = factory.compileSchema(dtd);
        Verifier verifier = schema.newVerifier();
        SaxCollector collector = new SaxCollector();
        verifier.setErrorHandler(collector);
        boolean valid = verifier.verify(xml);
        if (!collector.diagnostics.isEmpty()) {
            return collector.diagnostics;
        }
        if (!valid) {
            collector.diagnostics.add(new Diagnostic("", xml.getName(), 0, 0, "XML entspricht nicht der DTD"));
        }
        return collector.diagnostics;
    }

    private static Diagnostic buildPDF(String[] args) {
        FopCollector collector = new FopCollector();
        try (FileOutputStream output = new FileOutputStream(args[4])) {
            File config = new File(args[1]);
            FopFactory factory = new FopConfParser(config, config.getParentFile().toURI())
                    .getFopFactoryBuilder().build();
            FOUserAgent userAgent = factory.newFOUserAgent();
            userAgent.setLocatorEnabled(true);
            userAgent.getEventBroadcaster().addEventListener(collector::accept);
            Fop fop = factory.newFop(MimeConstants.MIME_PDF, userAgent, output);

            Transformer transformer = TransformerFactory.newInstance()
                    .newTransformer(new StreamSource(new File(args[3])));
            transformer.setParameter("Projektname", args[5]);
            transformer.setParameter("Projektpfad", args[6]);
            transformer.setParameter("SharedImagesPfad", args[7]);
            transformer.transform(new StreamSource(new File(args[2])), new SAXResult(fop.getDefaultHandler()));
            return null;
        } catch (Throwable failure) {
            return collector.first != null ? collector.first : Diagnostic.fromThrowable(failure);
        }
    }

    private static Diagnostic transformEPUB(String[] args) {
        SaxonCollector collector = new SaxonCollector();
        try {
            Processor processor = new Processor(false);
            XsltCompiler compiler = processor.newXsltCompiler();
            compiler.setErrorListener(collector);
            XsltExecutable executable = compiler.compile(new StreamSource(new File(args[2])));
            XsltTransformer transformer = executable.load();
            transformer.setErrorListener(collector);
            transformer.setMessageListener((content, errorCode, terminate, locator) -> { });
            transformer.setSource(new StreamSource(new File(args[1])));
            transformer.setParameter(new QName("Projekt"), new XdmAtomicValue(args[4]));
            transformer.setParameter(new QName("OutputRoot"), new XdmAtomicValue(args[5]));
            transformer.setParameter(new QName("CSSStylesheet"), new XdmAtomicValue(args[6]));
            Serializer destination = processor.newSerializer(new File(args[3]));
            transformer.setDestination(destination);
            transformer.transform();
            return null;
        } catch (Throwable failure) {
            return collector.first != null ? collector.first : Diagnostic.fromThrowable(failure);
        }
    }

    private static Diagnostic validateEPUB(File epub) {
        EPUBCollector collector = new EPUBCollector(epub.getAbsolutePath());
        try {
            int result = new EpubCheck(epub, collector).doValidate();
            if (collector.first != null) {
                return collector.first;
            }
            return result == 0 ? null : new Diagnostic("", epub.getName(), 0, 0, "EPUB ist nicht valide");
        } catch (Throwable failure) {
            return collector.first != null ? collector.first : Diagnostic.fromThrowable(failure);
        }
    }

    private static void requireArgs(String[] args, int count) {
        if (args.length < count) {
            throw new IllegalArgumentException("Unvollständiger Werkzeugaufruf");
        }
    }

    private static void emit(Diagnostic diagnostic) {
        PrintWriter writer = new PrintWriter(new OutputStreamWriter(System.out, StandardCharsets.UTF_8));
        writer.println(diagnostic.toJSON());
        writer.flush();
    }

    private static void emit(List<Diagnostic> diagnostics) {
        PrintWriter writer = new PrintWriter(new OutputStreamWriter(System.out, StandardCharsets.UTF_8));
        writer.print("[");
        for (int index = 0; index < diagnostics.size(); index++) {
            if (index > 0) {
                writer.print(",");
            }
            writer.print(diagnostics.get(index).toJSON());
        }
        writer.println("]");
        writer.flush();
    }

    private static final class SaxCollector implements ErrorHandler {
        private final List<Diagnostic> diagnostics = new ArrayList<>();
        private final Set<String> seen = new HashSet<>();

        @Override
        public void warning(SAXParseException exception) {
        }

        @Override
        public void error(SAXParseException exception) {
            capture(exception);
        }

        @Override
        public void fatalError(SAXParseException exception) {
            capture(exception);
        }

        private void capture(SAXParseException exception) {
            String message = exception.getMessage();
            if (exception instanceof ValidityViolation) {
                ErrorInfo info = ((ValidityViolation) exception).getErrorInfo();
                if (info instanceof ErrorInfo.BadTagName) {
                    message = "Element <" + ((ErrorInfo.BadTagName) info).qName
                            + "> ist an dieser Stelle nicht erlaubt";
                } else if (info instanceof ErrorInfo.BadAttribute) {
                    ErrorInfo.BadAttribute attribute = (ErrorInfo.BadAttribute) info;
                    message = "Attribut \"" + attribute.attQName + "\" ist am Element <"
                            + attribute.qName + "> nicht erlaubt";
                }
            }
            Diagnostic diagnostic = new Diagnostic("", exception.getSystemId(), exception.getLineNumber(),
                    exception.getColumnNumber(), message);
            String identity = diagnostic.file + "\u0000" + diagnostic.line + "\u0000"
                    + diagnostic.column + "\u0000" + diagnostic.message;
            if (seen.add(identity)) {
                diagnostics.add(diagnostic);
            }
        }
    }

    private static final class FopCollector {
        private Diagnostic first;

        private void accept(Event event) {
            if (first != null || (event.getSeverity() != EventSeverity.ERROR
                    && event.getSeverity() != EventSeverity.FATAL)) {
                return;
            }
            String message;
            if ("invalidPropertyValue".equals(event.getEventKey())) {
                message = "Ungültiger Wert \"" + text(event.getParam("propValue"))
                        + "\" für FOP-Eigenschaft \"" + text(event.getParam("propName")) + "\"";
            } else if ("missingProperty".equals(event.getEventKey())) {
                message = "Erforderliche FOP-Eigenschaft \"" + text(event.getParam("propertyName")) + "\" fehlt";
            } else {
                message = EventFormatter.format(event, Locale.GERMAN);
            }
            Object location = event.getParam("loc");
            if (!(location instanceof Locator)) {
                location = event.getParam("locator");
            }
            if (location instanceof Locator) {
                Locator locator = (Locator) location;
                first = new Diagnostic("", locator.getSystemId(), locator.getLineNumber(),
                        locator.getColumnNumber(), message);
            } else {
                first = new Diagnostic("", "", 0, 0, message);
            }
        }

        private static String text(Object value) {
            return value == null ? "" : value.toString();
        }
    }

    private static final class SaxonCollector implements ErrorListener {
        private Diagnostic first;

        @Override
        public void warning(TransformerException exception) {
        }

        @Override
        public void error(TransformerException exception) {
            capture(exception);
        }

        @Override
        public void fatalError(TransformerException exception) {
            capture(exception);
        }

        private void capture(TransformerException exception) {
            if (first == null) {
                first = Diagnostic.fromTransformerException(exception);
            }
        }
    }

    private static final class EPUBCollector extends MasterReport {
        private Diagnostic first;

        private EPUBCollector(String filename) {
            setEpubFileName(filename);
            setLocale(Locale.GERMAN);
        }

        @Override
        public void message(Message message, EPUBLocation location, Object... args) {
            Severity severity = message.getSeverity();
            if (first == null && (severity == Severity.ERROR || severity == Severity.FATAL)) {
                String text = args != null && args.length > 0 ? message.getMessage(args) : message.getMessage();
                first = new Diagnostic(message.getID().toString(), location.getPath(),
                        location.getLine(), location.getColumn(), text);
            }
        }

        @Override
        public void info(String resource, FeatureEnum feature, String value) {
        }

        @Override
        public int generate() {
            return getFatalErrorCount() + getErrorCount();
        }

        @Override
        public void initialize() {
        }
    }

    private static final class Diagnostic {
        private final String code;
        private final String file;
        private final int line;
        private final int column;
        private final String message;

        private Diagnostic(String code, String file, int line, int column, String message) {
            this.code = text(code);
            this.file = text(file);
            this.line = Math.max(0, line);
            this.column = Math.max(0, column);
            this.message = text(message).replaceAll("\\s+", " ").trim();
        }

        private static Diagnostic fromTransformerException(TransformerException exception) {
            SourceLocator locator = exception.getLocator();
            return new Diagnostic("", locator == null ? "" : locator.getSystemId(),
                    locator == null ? 0 : locator.getLineNumber(),
                    locator == null ? 0 : locator.getColumnNumber(), usefulMessage(exception));
        }

        private static Diagnostic fromThrowable(Throwable failure) {
            Throwable useful = failure;
            while (useful.getCause() != null && useful.getCause() != useful) {
                useful = useful.getCause();
            }
            if (useful instanceof SAXParseException) {
                SAXParseException sax = (SAXParseException) useful;
                return new Diagnostic("", sax.getSystemId(), sax.getLineNumber(), sax.getColumnNumber(),
                        usefulMessage(sax));
            }
            if (failure instanceof TransformerException) {
                return fromTransformerException((TransformerException) failure);
            }
            return new Diagnostic("", "", 0, 0, usefulMessage(useful));
        }

        private static String usefulMessage(Throwable failure) {
            String message = failure.getMessage();
            return message == null || message.trim().isEmpty()
                    ? failure.getClass().getSimpleName()
                    : message;
        }

        private String toJSON() {
            return "{\"code\":\"" + json(code) + "\",\"file\":\"" + json(file)
                    + "\",\"line\":" + line + ",\"column\":" + column
                    + ",\"message\":\"" + json(message) + "\"}";
        }

        private static String text(String value) {
            return value == null ? "" : value;
        }

        private static String json(String value) {
            StringBuilder escaped = new StringBuilder();
            for (int index = 0; index < value.length(); index++) {
                char character = value.charAt(index);
                switch (character) {
                    case '\\': escaped.append("\\\\"); break;
                    case '"': escaped.append("\\\""); break;
                    case '\n': escaped.append("\\n"); break;
                    case '\r': escaped.append("\\r"); break;
                    case '\t': escaped.append("\\t"); break;
                    default:
                        if (character < 0x20) {
                            escaped.append(String.format("\\u%04x", (int) character));
                        } else {
                            escaped.append(character);
                        }
                }
            }
            return escaped.toString();
        }
    }
}
