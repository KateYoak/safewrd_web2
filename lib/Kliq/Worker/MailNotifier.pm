package Kliq::Worker::MailNotifier;

use namespace::autoclean;
use Moose;
use Try::Tiny;
use Mail::Builder::Simple;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithMessage
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::DoesShortener
    /;

sub work {
    my ($self, $data) = @_;
    my $config = $self->config;

my $template = <<EOF;
[% sender %] added you to a "KLIQ", and wants to send a video message to you.
Please click "Accept Invitation" if you want to receive his/her video message(s).

<a href="[% shortlink %]">[% msg %]</a>
EOF

    try { 
        my $shortlink = $self->shorten($data->{contact_id}, $data->{media_id})
            or die("No short link");        
        
        my $mail = Mail::Builder::Simple->new;

        $mail->send(
            mail_client => {
                mailer => 'SMTP',
                mailer_args => {
                    ssl           => defined($config->{ssl}) ? $config->{ssl} : 0,
                    host          => $config->{host} || 'smtp.sendgrid.net',
                    port          => $config->{port} || 465,
                    sasl_username => $config->{user}, 
                    sasl_password => $config->{pass},
                    timeout       => 20   
               },
               #live_on_error => 1,
            },
            from => ['kliq@kliqmobile.com', 'KLIQ Mobile'], 
            to => $data->{email},
            # reply => 'info@kliqmobile.com',
            subject => $data->{sender} . ' shared a video with you',
            htmltext => $self->message(
                $data->{sender}, $data->{message}, $data->{upload_id}, 
                $data->{media_id}, $data->{contact_id}, $shortlink
            ),
            plaintext => [$template, ':TT-scalar'],
            template_vars => { 
                sender => $data->{sender}, 
                media_id => $data->{media_id}, 
                upload_id => $data->{upload_id}, 
                msg => $data->{message},
                shortlink => $shortlink
                },
            priority => 1,
            mailer => 'KLIQ Mailer 0.01',
        );
    
    } catch {
        my $error = $_;
        $self->logger->error($error);
    };
    $self->logger->info("message sent");

}

__PACKAGE__->meta->make_immutable;

1;
__DATA__
@@ body.html
<html>
    <body style="background-color: rgb(222,222,222); margin-top: 20px">
        <p style="padding-bottom: 0px; margin: 0px; padding-left: 0px; padding-right: 0px; padding-top: 0px"><style type="text/css">
<!--
.small {font-family:Helvetica, Arial;font-size:11px;color:#404243;}
p {color:#404243;}
a, a:visited, a:hover, a:link {color:#404243;text-decoration:underline;}
td {font-size:15px;}
.yshortcuts {color:#404243;border-bottom: none !important;}
.yshortcuts span {color:#404243;border-bottom: none !important;}
.yshortcuts a span {color:#404243;text-decoration:underline;font-weight:bold;border-bottom: none !important;}
.yshortcuts span a {color:#404243;text-decoration:underline;font-weight:bold;border-bottom: none !important;}
span .small .yshortcuts {font-family:Helvetica, Arial;font-size:18px;color:#404243;text-decoration:none;border-bottom: none !important;}
td.small span.yshortcuts {font-family:Helvetica, Arial;font-size:18px;color:#404243;text-decoration:none;border-bottom: none !important;}
td.small span.yshortcuts a {font-family:Helvetica, Arial;font-size:18px;color:#404243;text-decoration:none;border-bottom: none !important;}
img{margin:0;padding:0;border:0;display:block;}
.ReadMsgBody {width:100%;}
.ExternalClass {width:100%;}
div, p, a, li, td { -webkit-text-size-adjust:none; }
--></style></p>
        <table border="0" cellspacing="0" cellpadding="0" width="100%">
            <tbody>
                <tr>
                    <td bgcolor="#dedede">
                    <table border="0" cellspacing="0" cellpadding="0" width="447" bgcolor="#dedede" align="center">
                        <tbody>
                            <tr>
                                <td height="28" width="447">&nbsp;</td>
                            </tr>
                            <tr>
                            	<td width="447" height="20"><img title="" border="0" alt="" width="447" height="20" style="display: block" src="http://kliqmobile.com/images/email/email-top-top.gif" /></td>
                            </tr>
                            <tr>
                                <td valign="top" width="447" height="26" style="font-family:Helvetica, Arial; color: rgb(64,66,67); font-size: 18px">
                                   <table cellspacing="0" cellpadding="0" width="447">
                                        <tbody>
                                            <tr>
                                                <td width="28" height="26"><img title="" border="0" alt="" src="http://kliqmobile.com/images/email/email-top-left.gif" width="28" height="26"></td>
                                                <td width="328" height="26" style="background-color:#4b4b4b;font-family:Helvetica, Arial; color: rgb(255,255,255); font-size: 18px;">Hello[% recipient OR ',' %]</td>
                                                <td width="91" height="26"><img title="Kliqmobile.com" border="0" alt="Kliqmobile.com" src="http://kliqmobile.com/images/email/kliq-mobile-logo.gif" width="91" height="26"></td>
                                            </tr>
                                        </tbody>
                                    </table></td>
                            </tr>
                            <tr>
                            	<td width="447" height="23"><img title="" border="0" alt="" width="447" height="23" style="display: block" src="http://kliqmobile.com/images/email/email-top-bottom.gif" /></td>
                            </tr>
                            <tr>
                            	<td valign="top" width="445" style="font-family:Helvetica, Arial; color: rgb(64,66,67); border-left:1px solid #000000;border-right:1px solid #000000;;font-size: 18px">
                                	<table cellspacing="0" cellpadding="0" width="445">
                                        <tbody>
                                            <tr>
                            					<td width="6" style="background-color: rgb(75,75,75);">&nbsp;</td>
                                				<td width="413" style="border-left:1px solid #000000;border-right:1px solid #000000;padding-left:9px;padding-right:9px;background-color: rgb(241,246,250);">

<p style="line-height: 18px; font-family:Helvetica, Arial; margin-bottom: 10px; color: rgb(64,66,67); font-size: 12px">
    [% sender %] added you to his "<span style="color:#7a539c">KLIQ</span>", and wants to send a video message to you. Please click "Accept Invitation" if you want to receive his/her video message(s).
</p>
<p style="margin:0 auto;text-align:center;font-family:Helvetica, Arial;margin-bottom:10px;color:rgb(64,66,67);font-size:14px;">
    [% msg %]
</p>
<p style="width:150px;overflow:hidden;margin:0 122px;font-family:Helvetica, Arial;margin-bottom:10px;color:rgb(64,66,67);font-size:14px;">
    <a href="[% shortlink %]"><img style="margin:0 auto;max-width:150px;text-align:center;" align="center" src="/" alt="[% msg %]" /></a>
</p>
<p>
    <a href="[% shortlink %]" class="sharebutton"><img title="Accept Invitation" border="0" alt="Accept Invitation" id="sharebutton" src="http://kliqmobile.com/images/email/accept-invitation-button.gif" width="412" height="46" style="display: block"></a>
</p>

                                                </td>
                               					<td width="6" style="background-color: rgb(75,75,75);">&nbsp;</td>
                            				</tr>
                                           </tbody>
                                    </table></td>
                            </tr>
                            <tr>
                                <td height="29" width="447"><img title="" border="0" alt="" width="447" height="29" style="display: block" src="http://kliqmobile.com/images/email/email-bottom-bottom.gif" /></td>
                            </tr>
                        </tbody>
                    </table>
                    <table border="0" cellspacing="0" cellpadding="0" width="447" align="center">
                        <tbody>
                            <tr>
                                <td width="447" colspan="3">&nbsp;</td>
                            </tr>
                            <tr>
                                <td width="20">&nbsp;</td>
                                <td class="small" width="407" align="center">
                                <p class="small" style="font-family: Arial; color: rgb(0,0,0); font-size: 11px; text-algin: left">KLIQ Mobile, LLC, Birmingham, Michigan 48009, USA<br />
                                &copy;2012 KLIQ Mobile. All rights reserved.</p>
                                </td>
                                <td width="20">&nbsp;</td>
                            </tr>
                        </tbody>
                    </table>
                    </td>
                </tr>
            </tbody>
        </table>
    </body>
</html>

__END__
