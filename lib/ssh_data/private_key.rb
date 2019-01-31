module SSHData
  module PrivateKey
    OPENSSH_PEM_TYPE = "OPENSSH PRIVATE KEY"
    RSA_PEM_TYPE     = "RSA PRIVATE KEY"
    DSA_PEM_TYPE     = "DSA PRIVATE KEY"
    ECDSA_PEM_TYPE   = "EC PRIVATE KEY"

    # Parse an SSH private key.
    #
    # key - An PEM encoded OpenSSH private key.
    #
    # Returns an Array of PrivateKey::Base subclass instances.
    def self.parse(key)
      case Encoding.pem_type(key)
      when OPENSSH_PEM_TYPE
        parse_openssh(key)
      when RSA_PEM_TYPE
        [RSA.from_openssl(OpenSSL::PKey::RSA.new(key))]
      when DSA_PEM_TYPE
        [DSA.from_openssl(OpenSSL::PKey::DSA.new(key))]
      when ECDSA_PEM_TYPE
        [ECDSA.from_openssl(OpenSSL::PKey::EC.new(key))]
      end
    rescue OpenSSL::PKey::PKeyError => e
      raise DecodeError, "bad private key. maybe encrypted?"
    end

    def self.parse_openssh(key)
      raw = Encoding.decode_pem(key, OPENSSH_PEM_TYPE)

      data, read = Encoding.decode_openssh_private_key(raw)
      unless read == raw.bytesize
        raise DecodeError, "unexpected trailing data"
      end

      from_data(data)
    end

    def self.from_data(data)
      data[:private_keys].map do |priv|
        case priv[:algo]
        when PublicKey::ALGO_RSA
          RSA.new(**priv)
        when PublicKey::ALGO_DSA
          DSA.new(**priv)
        when PublicKey::ALGO_ECDSA256, PublicKey::ALGO_ECDSA384, PublicKey::ALGO_ECDSA521
          ECDSA.new(**priv)
        when PublicKey::ALGO_ED25519
          ED25519.new(**priv)
        else
          raise DecodeError, "unkown algo: #{priv[:algo].inspect}"
        end
      end
    end
  end
end

require "ssh_data/private_key/base"
require "ssh_data/private_key/rsa"
require "ssh_data/private_key/dsa"
require "ssh_data/private_key/ecdsa"
require "ssh_data/private_key/ed25519"