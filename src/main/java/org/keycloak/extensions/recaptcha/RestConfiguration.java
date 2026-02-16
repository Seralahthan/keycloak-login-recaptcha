package org.keycloak.extensions.recaptcha;

import org.jboss.logging.Logger;
import java.util.Map;

import static java.lang.Integer.parseInt;

public class RestConfiguration {

	public static final String MAX_HTTP_CONNECTIONS = "maxHttpConnections";
	public static final String API_SOCKET_TIMEOUT = "apiSocketTimeout";
	public static final String API_CONNECT_TIMEOUT = "apiConnectTimeout";
	public static final String API_CONNECTION_REQUEST_TIMEOUT = "apiConnectionRequestTimeout";
	public static final String HTTP_STATS_INTERVAL = "httpStatsInterval";

	private static final Logger logger = Logger.getLogger(RestConfiguration.class);

	private final Integer maxConnections;
	private final Integer apiSocketTimeout;
	private final Integer apiConnectTimeout;
	private final Integer apiConnectionRequestTimeout;
	private final Integer httpStatsInterval;

	public Integer getMaxConnections() {
		return maxConnections;
	}

	public Integer getApiSocketTimeout() {
		return apiSocketTimeout;
	}

	public Integer getApiConnectTimeout() {
		return apiConnectTimeout;
	}

	public Integer getApiConnectionRequestTimeout() {
		return apiConnectionRequestTimeout;
	}

	public Integer getHttpStatsInterval() {
		return httpStatsInterval;
	}

	public RestConfiguration(Map<String, String> keycloakConfig) {
		this.maxConnections = parseInt(keycloakConfig.getOrDefault(MAX_HTTP_CONNECTIONS, "10"));
		logger.infov("Loaded maxHttpConnections from module properties: {0}", maxConnections);

		this.apiSocketTimeout = parseInt(keycloakConfig.getOrDefault(API_SOCKET_TIMEOUT, "5000"));
		logger.infov("Loaded apiSocketTimeout from module properties: {0}", apiSocketTimeout);

		this.apiConnectTimeout = parseInt(keycloakConfig.getOrDefault(API_CONNECT_TIMEOUT, "5000"));
		logger.infov("Loaded apiConnectTimeout from module properties: {0}", apiConnectTimeout);

		this.apiConnectionRequestTimeout = parseInt(keycloakConfig.getOrDefault(API_CONNECTION_REQUEST_TIMEOUT, "5000"));
		logger.infov("Loaded apiConnectionRequestTimeout from module properties: {0}", apiConnectionRequestTimeout);

		this.httpStatsInterval = parseInt(keycloakConfig.getOrDefault(HTTP_STATS_INTERVAL, "60"));
		logger.infov("Loaded httpStatsInterval from module properties: {0}", httpStatsInterval);
	}

	@Override
	public String toString() {
		StringBuffer buffer = new StringBuffer();
		buffer.append("maxConnections: " + maxConnections + "; ");
		buffer.append("apiSocketTimeout: " + apiSocketTimeout + "; ");
		buffer.append("apiConnectTimeout: " + apiConnectTimeout + "; ");
		buffer.append("apiConnectionRequestTimeout: " + apiConnectionRequestTimeout);

		return buffer.toString();
	}
}
